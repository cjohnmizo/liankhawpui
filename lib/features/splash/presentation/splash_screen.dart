import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liankhawpui/core/config/app_assets.dart';
import 'package:liankhawpui/core/providers/sync_providers.dart';
import 'package:liankhawpui/core/services/powersync_service.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';
import 'dart:async';
import 'package:powersync/powersync.dart' show SyncStatus;

const bool _testMode = bool.fromEnvironment('TEST_MODE', defaultValue: false);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _continueTimer;
  bool _showContinueAction = false;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  Future<void> _handleStartup() async {
    if (!_testMode) {
      await Future.delayed(const Duration(milliseconds: 450));
    }
    try {
      await ref.read(powerSyncServiceProvider).ensureLocalDatabaseReady();
    } catch (e) {
      debugPrint('WARN: splash could not verify local DB readiness: $e');
    }
    _goHome();

    _continueTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && !_didNavigate && !_showContinueAction) {
        setState(() => _showContinueAction = true);
      }
    });
  }

  void _goHome() {
    if (!mounted || _didNavigate) return;
    try {
      _didNavigate = true;
      context.go('/');
    } catch (_) {
      _didNavigate = false;
      if (mounted) setState(() => _showContinueAction = true);
    }
  }

  @override
  void dispose() {
    _continueTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(powerSyncServiceProvider);
    final user = ref.watch(currentUserProvider);
    final statusAsync = ref.watch(powerSyncStatusProvider);
    final statusText = _buildStatusMessage(
      service: service,
      status: statusAsync.valueOrNull,
      statusIsLoading: statusAsync.isLoading,
      isGuest: user.isGuest,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Image(
                    image: AssetImage(AppAssets.appLogo),
                    width: 140,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  const _LogoPaletteText(
                    text: 'LIANKHAWPUI',
                    style: TextStyle(
                      fontSize: 22,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 220,
                    child: Text(
                      statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (_showContinueAction) ...[
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _goHome,
                      child: const Text(
                        'Continue',
                        style: TextStyle(color: AppColors.accentGold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Column(
                children: [
                  const Text(
                    'Developed by',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _LogoPaletteText(
                    text: 'C. John',
                    style: GoogleFonts.greatVibes(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildStatusMessage({
    required bool statusIsLoading,
    required bool isGuest,
    required SyncStatus? status,
    required PowerSyncService service,
  }) {
    if (statusIsLoading) {
      return 'Starting local services...';
    }
    if (service.isRemoteSyncEnabled == false) {
      return 'Offline cache ready.';
    }
    if (isGuest) {
      return 'Opening app...';
    }
    if (status == null) {
      return 'Preparing sync...';
    }
    if (status.connecting) {
      return 'Connecting sync service...';
    }
    if (status.downloading || status.uploading) {
      return 'Syncing latest data...';
    }
    if (status.connected) {
      return 'Opening app...';
    }
    if (status.anyError != null) {
      return 'Network issue detected. Opening cached data.';
    }
    return 'Opening app...';
  }
}

class _LogoPaletteText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _LogoPaletteText({required this.text, required this.style});

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
