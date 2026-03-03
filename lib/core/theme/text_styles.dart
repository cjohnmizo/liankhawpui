import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';

/// Minimal typography scale.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _manrope({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    double height = 1.4,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle displayLarge = _manrope(
    size: 34,
    weight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static TextStyle displayMedium = _manrope(
    size: 28,
    weight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static TextStyle displaySmall = _manrope(size: 24, weight: FontWeight.w700);

  static TextStyle headlineLarge = _manrope(size: 22, weight: FontWeight.w700);
  static TextStyle headlineMedium = _manrope(size: 20, weight: FontWeight.w700);
  static TextStyle headlineSmall = _manrope(size: 18, weight: FontWeight.w700);

  static TextStyle titleLarge = _manrope(size: 18, weight: FontWeight.w600);
  static TextStyle titleMedium = _manrope(size: 16, weight: FontWeight.w600);
  static TextStyle titleSmall = _manrope(size: 14, weight: FontWeight.w600);

  static TextStyle bodyLarge = _manrope(
    size: 16,
    weight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.55,
  );

  static TextStyle bodyMedium = _manrope(
    size: 14,
    weight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle bodySmall = _manrope(
    size: 12,
    weight: FontWeight.w500,
    color: AppColors.textTertiary,
    height: 1.4,
  );

  static TextStyle labelLarge = _manrope(
    size: 14,
    weight: FontWeight.w700,
    color: AppColors.accentGold,
    letterSpacing: 0.2,
  );

  static TextStyle labelMedium = _manrope(
    size: 12,
    weight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  static TextStyle labelSmall = _manrope(
    size: 11,
    weight: FontWeight.w700,
    color: AppColors.textTertiary,
    letterSpacing: 0.2,
  );

  static TextStyle button = _manrope(size: 15, weight: FontWeight.w700);
  static TextStyle goldButton = _manrope(
    size: 15,
    weight: FontWeight.w700,
    color: Colors.white,
  );

  static TextStyle caption = _manrope(
    size: 11,
    weight: FontWeight.w500,
    color: AppColors.textTertiary,
  );

  static TextStyle overline = _manrope(
    size: 10,
    weight: FontWeight.w700,
    color: AppColors.textTertiary,
    letterSpacing: 0.8,
  );

  static TextStyle withGold(TextStyle style) =>
      style.copyWith(color: AppColors.accentGold);
  static TextStyle withWhite(TextStyle style) =>
      style.copyWith(color: AppColors.textPrimary);
  static TextStyle withSecondary(TextStyle style) =>
      style.copyWith(color: AppColors.textSecondary);
  static TextStyle withBold(TextStyle style) =>
      style.copyWith(fontWeight: FontWeight.w700);
  static TextStyle withSemiBold(TextStyle style) =>
      style.copyWith(fontWeight: FontWeight.w600);
}
