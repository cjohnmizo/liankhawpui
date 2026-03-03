import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:liankhawpui/core/config/env_config.dart';

class OneSignalService {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    final appId = EnvConfig.oneSignalAppId;
    if (appId.isEmpty) {
      debugPrint(
        'ONESIGNAL_APP_ID is not configured. Push notifications are disabled.',
      );
      return;
    }

    OneSignal.initialize(appId);

    if (kDebugMode) {
      await OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    }

    _isInitialized = true;
  }

  static Future<void> requestNotificationPermission() async {
    if (!_isInitialized || kIsWeb) return;
    await OneSignal.Notifications.requestPermission(false);
  }

  static Future<void> syncExternalUserId(String? userId) async {
    if (!_isInitialized || kIsWeb) return;

    final safeUserId = userId?.trim();
    if (safeUserId == null || safeUserId.isEmpty || safeUserId == 'guest') {
      await OneSignal.logout();
      return;
    }

    await OneSignal.login(safeUserId);
  }
}
