import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:liankhawpui/core/config/env_config.dart';
import 'package:liankhawpui/core/theme/app_theme.dart';
import 'package:liankhawpui/core/theme/theme_provider.dart';
import 'package:liankhawpui/core/services/supabase_service.dart';
import 'package:liankhawpui/core/services/powersync_service.dart';
import 'package:liankhawpui/core/services/onesignal_service.dart';
import 'package:liankhawpui/core/router/app_router.dart';
import 'package:liankhawpui/core/widgets/network_status_overlay.dart';

const bool _testMode = bool.fromEnvironment('TEST_MODE', defaultValue: false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    EnvConfig.validateRequired();

    // Initialize Backend Services
    await SupabaseService.initialize();
    await PowerSyncService().initialize(enableRemoteSync: false);

    runApp(const ProviderScope(child: LiankhawpuiApp()));

    if (_testMode) {
      debugPrint(
        'TEST_MODE is enabled: remote PowerSync sync and OneSignal are disabled.',
      );
      return;
    }

    // Keep first render fast; initialize remote services after app start.
    unawaited(_initializeDeferredServices());
  } catch (e) {
    debugPrint('CRITICAL: app initialization failed: $e');
    runApp(AppBootstrapError(error: e.toString()));
  }
}

Future<void> _initializeDeferredServices() async {
  try {
    await PowerSyncService().initialize(enableRemoteSync: true);
  } catch (e) {
    debugPrint('WARN: PowerSync remote sync initialization failed: $e');
  }

  try {
    await OneSignalService.initialize();
    await OneSignalService.requestNotificationPermission();
    await OneSignalService.syncExternalUserId(
      SupabaseService.client.auth.currentUser?.id,
    );
  } catch (e) {
    debugPrint('WARN: OneSignal initialization failed: $e');
  }
}

class LiankhawpuiApp extends ConsumerWidget {
  const LiankhawpuiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Liankhawpui',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return NetworkStatusOverlay(child: child);
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppBootstrapError extends StatelessWidget {
  final String error;

  const AppBootstrapError({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'App configuration error.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
