import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:liankhawpui/core/config/app_assets.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';

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
    // 1.5s delay to allow signature to be read, seamless transition from native splash
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Navigate to root (which handles auth redirect)
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    // Force dark background to match native splash (which is black)
    // This ensures seamless transition even if system is light mode initially
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : Colors.black, // Match native splash black
      body: Stack(
        children: [
          // Background Gradient (Optional, or just Black to match native)
          // To be perfectly seamless with native (Black), we should start Black.
          // But user wants Premium.
          // Native is Black + Logo.
          // Flutter Splash will be Black + Logo + Signature.
          Container(
            color: Colors.black, // Base
          ),

          // Centered Logo
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo - Using Image.asset directly to ensure exact match with t_logo
                // AppLogo uses t_logo too, but let's be explicit or use AppLogo.
                Image.asset(
                      AppAssets.appLogo,
                      width:
                          160, // Match typical native splash size or slightly larger
                      fit: BoxFit.contain,
                    )
                    .animate()
                    .fadeIn(
                      duration: 300.ms,
                    ) // Quick fade in case of slight mismatch
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: 1500.ms,
                    ), // Subtle breathing

                const SizedBox(height: 24),

                // App Name
                Text(
                      'LIANKHAWPUI',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: AppColors.accentGold,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),

          // Developer Credit with Signature
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Developed by',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 2,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 8),
                Text(
                      'C. John',
                      style: GoogleFonts.greatVibes(
                        fontSize: 36,
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 700.ms)
                    .shimmer(duration: 1500.ms, delay: 1000.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
