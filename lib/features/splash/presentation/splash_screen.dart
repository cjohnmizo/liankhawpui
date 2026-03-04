import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liankhawpui/core/config/app_assets.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';

const bool _testMode = bool.fromEnvironment('TEST_MODE', defaultValue: false);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  Future<void> _handleStartup() async {
    if (!_testMode) {
      await Future.delayed(const Duration(milliseconds: 350));
    }
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(
              image: AssetImage(AppAssets.appLogo),
              width: 140,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 12),
            Text(
              'LIANKHAWPUI',
              style: TextStyle(
                color: AppColors.accentGold,
                fontSize: 22,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
