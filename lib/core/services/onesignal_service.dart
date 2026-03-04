import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:liankhawpui/core/config/env_config.dart';

class OneSignalService {
  static bool _isInitialized = false;
  static bool _isDisabled = false;

  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    if (_isInitialized || _isDisabled || kIsWeb) return;

    final appId = EnvConfig.oneSignalAppId;
    if (appId.isEmpty) {
      debugPrint(
        'ONESIGNAL_APP_ID is not configured. Push notifications are disabled.',
      );
      _isDisabled = true;
      return;
    }

    try {
      OneSignal.initialize(appId);

      if (kDebugMode) {
        await OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      }

      _isInitialized = true;
    } catch (error) {
      _isDisabled = true;
      debugPrint('OneSignal initialization failed. Push disabled: $error');
    }
  }

  static Future<void> requestNotificationPermission() async {
    if (!_isInitialized || _isDisabled || kIsWeb) return;
    try {
      await OneSignal.Notifications.requestPermission(false);
    } catch (error) {
      debugPrint('OneSignal permission request failed: $error');
    }
  }

  static Future<void> syncExternalUserId(String? userId) async {
    if (!_isInitialized || _isDisabled || kIsWeb) return;

    final safeUserId = userId?.trim();
    try {
      if (safeUserId == null || safeUserId.isEmpty || safeUserId == 'guest') {
        await OneSignal.logout();
        return;
      }

      await OneSignal.login(safeUserId);
    } catch (error) {
      debugPrint('OneSignal user sync failed: $error');
    }
  }
}
