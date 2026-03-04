import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:liankhawpui/core/config/env_config.dart';
import 'package:liankhawpui/core/router/app_router.dart';

class OneSignalService {
  static bool _isInitialized = false;
  static bool _isDisabled = false;
  static bool _clickListenerAttached = false;
  static String? _lastExternalUserId;
  static String? _pendingAnnouncementId;

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

      if (!_clickListenerAttached) {
        OneSignal.Notifications.addClickListener(_onNotificationClicked);
        _clickListenerAttached = true;
      }

      if (kDebugMode) {
        await OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      }

      _isInitialized = true;
      flushPendingNavigation();
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

  static void flushPendingNavigation() {
    final pendingId = _pendingAnnouncementId?.trim();
    if (pendingId == null || pendingId.isEmpty) return;
    if (_openAnnouncementRoute(pendingId)) {
      _pendingAnnouncementId = null;
    }
  }

  static void _onNotificationClicked(OSNotificationClickEvent event) {
    final announcementId = _extractAnnouncementId(event)?.trim();
    if (announcementId == null || announcementId.isEmpty) {
      return;
    }

    if (!_openAnnouncementRoute(announcementId)) {
      _pendingAnnouncementId = announcementId;
    }
  }

  static String? _extractAnnouncementId(OSNotificationClickEvent event) {
    final data = event.notification.additionalData;
    final type = data?['type']?.toString().trim().toLowerCase();
    final idFromData =
        _normalizeId(data?['announcement_id']) ??
        _normalizeId(data?['announcementId']);

    if (idFromData != null &&
        (type == null || type.isEmpty || type == 'announcement')) {
      return idFromData;
    }

    return _extractAnnouncementIdFromUrl(event.result.url) ??
        _extractAnnouncementIdFromUrl(event.notification.launchUrl);
  }

  static String? _extractAnnouncementIdFromUrl(String? rawUrl) {
    final trimmed = rawUrl?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    final segments = uri.pathSegments
        .where((value) => value.isNotEmpty)
        .toList();

    if (uri.scheme == 'liankhawpui' && uri.host == 'announcement') {
      if (segments.isNotEmpty) {
        return _normalizeId(segments.first);
      }
      return null;
    }

    for (var i = 0; i < segments.length - 1; i++) {
      if (segments[i] == 'announcement') {
        return _normalizeId(segments[i + 1]);
      }
    }

    return null;
  }

  static String? _normalizeId(Object? value) {
    final parsed = value?.toString().trim();
    if (parsed == null || parsed.isEmpty) return null;
    return parsed;
  }

  static bool _openAnnouncementRoute(String announcementId) {
    final context = appNavigatorKey.currentContext;
    if (context == null) return false;

    final router = GoRouter.of(context);
    router.go('/announcement/$announcementId');
    return true;
  }
}
