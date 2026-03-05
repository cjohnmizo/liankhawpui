import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liankhawpui/core/config/app_assets.dart';
import 'package:liankhawpui/core/config/env_config.dart';
import 'package:liankhawpui/core/providers/app_preferences_provider.dart';
import 'package:liankhawpui/core/theme/app_theme.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/theme_provider.dart';
import 'package:liankhawpui/core/services/supabase_service.dart';
import 'package:liankhawpui/core/services/powersync_service.dart';
import 'package:liankhawpui/core/services/onesignal_service.dart';
import 'package:liankhawpui/core/router/app_router.dart';
import 'package:liankhawpui/core/widgets/network_status_overlay.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const bool _testMode = bool.fromEnvironment('TEST_MODE', defaultValue: false);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AppBootstrapGate()));
}

class AppBootstrapGate extends StatefulWidget {
  const AppBootstrapGate({super.key});

  @override
  State<AppBootstrapGate> createState() => _AppBootstrapGateState();
}

class _AppBootstrapGateState extends State<AppBootstrapGate> {
  bool _ready = false;
  String? _bootstrapError;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      await dotenv.load(fileName: '.env');
      EnvConfig.validateRequired();

      await _runWithTimeout(
        'Supabase',
        SupabaseService.initialize(),
        timeout: const Duration(seconds: 12),
      );

      if (!mounted) return;
      setState(() => _ready = true);

      if (_testMode) {
        unawaited(_initializeLocalPowerSyncOnly());
        debugPrint(
          'TEST_MODE is enabled: remote PowerSync sync and OneSignal are disabled.',
        );
        return;
      }

      // Keep first render fast; initialize remote services after app start.
      unawaited(_initializeDeferredServices());
    } catch (e) {
      if (!mounted) return;
      setState(() => _bootstrapError = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bootstrapError != null) {
      return AppBootstrapError(error: _bootstrapError!);
    }
    if (_ready) {
      return const LiankhawpuiApp();
    }
    return const AppBootstrapSplash();
  }
}

class AppBootstrapSplash extends StatelessWidget {
  const AppBootstrapSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image(
                      image: AssetImage(AppAssets.appLogo),
                      width: 140,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 12),
                    _BootstrapLogoText(
                      text: 'LIANKHAWPUI',
                      style: TextStyle(
                        fontSize: 22,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Starting app...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 14,
                child: Column(
                  children: [
                    Text(
                      'Developed by',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    _BootstrapSignatureText(text: 'C. John'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BootstrapSignatureText extends StatelessWidget {
  final String text;

  const _BootstrapSignatureText({required this.text});

  @override
  Widget build(BuildContext context) {
    return _BootstrapLogoText(
      text: text,
      style: GoogleFonts.greatVibes(fontSize: 26, fontWeight: FontWeight.w500),
    );
  }
}

class _BootstrapLogoText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _BootstrapLogoText({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.accentGoldLight,
        AppColors.accentGold,
        AppColors.accentGoldDark,
      ],
    );

    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        style: style.copyWith(
          color: Colors.white,
          shadows: const [
            Shadow(
              color: Color(0x33000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

Future<T> _runWithTimeout<T>(
  String label,
  Future<T> task, {
  Duration timeout = const Duration(seconds: 12),
}) async {
  try {
    return await task.timeout(timeout);
  } on TimeoutException {
    throw StateError(
      '$label initialization timed out after ${timeout.inSeconds}s.',
    );
  }
}

Future<void> _initializeDeferredServices() async {
  await _ensureGuestSessionForPublicSync();
  await PowerSyncService().startAutoSyncLifecycle();

  try {
    await OneSignalService.initialize();
    await OneSignalService.syncExternalUserId(
      SupabaseService.client.auth.currentUser?.id,
    );
  } catch (e) {
    debugPrint('WARN: OneSignal initialization failed: $e');
  }
}

Future<void> _ensureGuestSessionForPublicSync() async {
  final auth = SupabaseService.client.auth;
  if (auth.currentSession != null) return;

  try {
    await auth.signInAnonymously();
  } on AuthException catch (e) {
    debugPrint(
      'WARN: Anonymous guest sign-in failed. Guest sync may be empty: ${e.message}',
    );
  } catch (e) {
    debugPrint('WARN: Anonymous guest sign-in failed: $e');
  }
}

Future<void> _initializeLocalPowerSyncOnly() async {
  try {
    await PowerSyncService().initialize(enableRemoteSync: false);
  } catch (e) {
    debugPrint('WARN: local PowerSync initialization failed: $e');
  }
}

class LiankhawpuiApp extends ConsumerWidget {
  const LiankhawpuiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OneSignalService.flushPendingNavigation();
    });

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final textScaleFactor = ref.watch(textScaleFactorProvider);

    return MaterialApp.router(
      title: 'Liankhawpui',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final mediaQuery = MediaQuery.of(context);
        final scaledChild = MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: child,
        );
        return NetworkStatusOverlay(child: scaledChild);
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
