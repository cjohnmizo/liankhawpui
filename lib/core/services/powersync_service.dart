import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState;
import 'package:liankhawpui/core/services/supabase_service.dart';
import 'package:liankhawpui/data/local/db_schema.dart';
import 'package:liankhawpui/data/sync/supabase_connector.dart';

class PowerSyncService {
  static final PowerSyncService _instance = PowerSyncService._internal();
  factory PowerSyncService() => _instance;
  PowerSyncService._internal();

  late final PowerSyncDatabase db;
  bool _isInitialized = false;
  bool _isConnected = false;
  bool _remoteSyncEnabled = true;
  SupabaseConnector? _connector;
  bool _lifecycleStarted = false;
  bool _syncInFlight = false;
  StreamSubscription<AuthState>? _authStateSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _retryTimer;

  static const Duration _retryDelay = Duration(seconds: 8);

  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  bool get isRemoteSyncEnabled => _remoteSyncEnabled;

  Stream<SyncStatus> get statusStream => db.statusStream;
  SyncStatus get currentStatus => db.currentStatus;

  Future<void> initialize({bool enableRemoteSync = true}) async {
    _remoteSyncEnabled = enableRemoteSync;
    await _ensureDatabaseInitialized();

    if (!enableRemoteSync) {
      await _disconnectIfNeeded();
      return;
    }

    await _connectIfNeeded();
  }

  Future<void> startAutoSyncLifecycle() async {
    _remoteSyncEnabled = true;
    await _ensureDatabaseInitialized();

    if (_lifecycleStarted) {
      await _attemptAutoSync(reason: 'app_resume');
      return;
    }

    _lifecycleStarted = true;
    await _authStateSubscription?.cancel();
    await _connectivitySubscription?.cancel();
    _authStateSubscription = SupabaseService.client.auth.onAuthStateChange
        .listen(_onAuthStateChanged);

    final connectivity = Connectivity();
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((
      result,
    ) {
      if (_isOffline(result)) {
        unawaited(_disconnectIfNeeded());
        return;
      }
      unawaited(_attemptAutoSync(reason: 'network_online'));
    });

    await _attemptAutoSync(reason: 'startup');
  }

  Future<void> syncNow() async {
    if (!_isInitialized || !_remoteSyncEnabled) return;
    if (_syncInFlight) return;

    await _attemptAutoSync(reason: 'manual_sync_prepare');
    if (!_isConnected || _syncInFlight) return;

    _syncInFlight = true;

    try {
      await db.disconnect();
      _isConnected = false;

      _connector ??= SupabaseConnector(db);
      await db.connect(connector: _connector!);
      _isConnected = true;
      _cancelRetry();
    } catch (error) {
      _isConnected = false;
      debugPrint('PowerSync manual sync failed: $error');
      _scheduleRetry();
    } finally {
      _syncInFlight = false;
    }
  }

  Future<UploadQueueStats> getUploadQueueStats({
    bool includeSize = true,
  }) async {
    if (!_isInitialized) {
      return UploadQueueStats(count: 0, size: includeSize ? 0 : null);
    }
    return db.getUploadQueueStats(includeSize: includeSize);
  }

  Stream<UploadQueueStats> watchUploadQueueStats({
    Duration pollInterval = const Duration(seconds: 5),
    bool includeSize = true,
  }) async* {
    while (true) {
      try {
        yield await getUploadQueueStats(includeSize: includeSize);
      } catch (_) {
        yield UploadQueueStats(count: 0, size: includeSize ? 0 : null);
      }
      await Future<void>.delayed(pollInterval);
    }
  }

  Future<void> _ensureDatabaseInitialized() async {
    if (_isInitialized) return;

    final dir = await getApplicationSupportDirectory();
    final path = join(dir.path, 'liankhawpui.db');

    db = PowerSyncDatabase(schema: schema, path: path);
    await db.initialize();
    _isInitialized = true;
  }

  Future<void> _connectIfNeeded() async {
    if (_isConnected) return;

    final session = SupabaseService.client.auth.currentSession;
    if (session == null) {
      return;
    }

    if (!await _isNetworkOnline()) {
      return;
    }

    _connector ??= SupabaseConnector(db);
    await db.connect(connector: _connector!);
    _isConnected = true;
    _cancelRetry();
  }

  Future<void> _disconnectIfNeeded() async {
    if (!_isInitialized || !_isConnected) return;
    await db.disconnect();
    _isConnected = false;
  }

  Future<void> _attemptAutoSync({required String reason}) async {
    if (!_remoteSyncEnabled || _syncInFlight) return;
    _syncInFlight = true;

    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session == null) {
        await _disconnectIfNeeded();
        _cancelRetry();
        return;
      }

      if (!await _isNetworkOnline()) {
        await _disconnectIfNeeded();
        _scheduleRetry();
        return;
      }

      await initialize(enableRemoteSync: true);
      _cancelRetry();
    } catch (error) {
      _isConnected = false;
      debugPrint('PowerSync auto-sync failed ($reason): $error');
      _scheduleRetry();
    } finally {
      _syncInFlight = false;
    }
  }

  void _onAuthStateChanged(AuthState state) {
    switch (state.event) {
      case AuthChangeEvent.signedOut:
      // ignore: deprecated_member_use
      case AuthChangeEvent.userDeleted:
        unawaited(_disconnectIfNeeded());
        _cancelRetry();
        return;
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.passwordRecovery:
      case AuthChangeEvent.mfaChallengeVerified:
        unawaited(_attemptAutoSync(reason: 'auth_${state.event.name}'));
        return;
    }
  }

  Future<bool> _isNetworkOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !_isOffline(result);
  }

  bool _isOffline(List<ConnectivityResult> values) {
    if (values.isEmpty) return true;
    return values.every((value) => value == ConnectivityResult.none);
  }

  void _scheduleRetry() {
    if (_retryTimer?.isActive ?? false) return;
    _retryTimer = Timer(_retryDelay, () {
      _retryTimer = null;
      unawaited(_attemptAutoSync(reason: 'retry_timer'));
    });
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}
