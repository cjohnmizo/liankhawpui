import 'package:powersync/powersync.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
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

  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  bool get isRemoteSyncEnabled => _remoteSyncEnabled;

  Stream<SyncStatus> get statusStream => db.statusStream;
  SyncStatus get currentStatus => db.currentStatus;

  Future<void> initialize({bool enableRemoteSync = true}) async {
    _remoteSyncEnabled = enableRemoteSync;

    if (!_isInitialized) {
      final dir = await getApplicationSupportDirectory();
      final path = join(dir.path, 'liankhawpui.db');

      // Open the database
      db = PowerSyncDatabase(schema: schema, path: path);
      await db.initialize();

      _isInitialized = true;
    }

    if (enableRemoteSync && !_isConnected) {
      // Create and connect the connector only when remote sync is enabled.
      _connector ??= SupabaseConnector(db);
      await db.connect(connector: _connector!);
      _isConnected = true;
    } else if (!enableRemoteSync && _isConnected) {
      await db.disconnect();
      _isConnected = false;
    }
  }

  Future<void> syncNow() async {
    if (!_isInitialized || !_remoteSyncEnabled) return;

    _connector ??= SupabaseConnector(db);
    await db.disconnect();
    _isConnected = false;

    await db.connect(connector: _connector!);
    _isConnected = true;
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
}
