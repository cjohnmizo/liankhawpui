import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:liankhawpui/core/config/env_config.dart';

class OneSignalService {
  static bool _isInitialized = false;
  static bool _isDisabled = false;
  static String? _lastExternalUserId;

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
      if (!OneSignal.Notifications.permission) {
        await OneSignal.Notifications.requestPermission(true);
      }
      if (OneSignal.Notifications.permission) {
        await OneSignal.User.pushSubscription.optIn();
      }
    } catch (error) {
      debugPrint('OneSignal permission request failed: $error');
    }
  }

  static Future<void> syncExternalUserId(String? userId) async {
    if (!_isInitialized || _isDisabled || kIsWeb) return;

    final safeUserId = userId?.trim();
    try {
      if (safeUserId == null || safeUserId.isEmpty || safeUserId == 'guest') {
        // Avoid logging out on cold start when there was never a mapped user.
        if (_lastExternalUserId != null) {
          await OneSignal.logout();
          _lastExternalUserId = null;
        }
        return;
      }

      await OneSignal.login(safeUserId);
      _lastExternalUserId = safeUserId;
    } catch (error) {
      debugPrint('OneSignal user sync failed: $error');
    }
  }

  static String? currentSubscriptionId() {
    if (!_isInitialized || _isDisabled || kIsWeb) return null;
    final value = OneSignal.User.pushSubscription.id?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }
}
