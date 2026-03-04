import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/config/app_assets.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'dart:async';

const bool _testMode = bool.fromEnvironment('TEST_MODE', defaultValue: false);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _retryTimer;
  bool _showContinueAction = false;

  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  Future<void> _handleStartup() async {
    if (!_testMode) {
      await Future.delayed(const Duration(milliseconds: 350));
    }
    _goHome();

    // Retry navigation for a few seconds in case router state is still settling.
    var attempts = 0;
    _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      attempts += 1;
      _goHome();

      if (attempts >= 4 && mounted && !_showContinueAction) {
        setState(() => _showContinueAction = true);
      }
      if (attempts >= 10) {
        timer.cancel();
      }
    });
  }

  void _goHome() {
    if (!mounted) return;
    try {
      context.go('/');
    } catch (_) {
      // Best effort: periodic retry + manual continue button handle transient router timing.
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Image(
              image: AssetImage(AppAssets.appLogo),
              width: 140,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            const Text(
              'LIANKHAWPUI',
              style: TextStyle(
                color: AppColors.accentGold,
                fontSize: 22,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
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
    );
  }
}
