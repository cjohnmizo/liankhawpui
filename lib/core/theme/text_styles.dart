import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';

/// Premium Typography System
class AppTextStyles {
  AppTextStyles._(); // Private constructor

  // ============================================================================
  // Display Styles (Large, Prominent)
  // ============================================================================

  /// Display Large - For hero sections
  static TextStyle displayLarge = GoogleFonts.playfairDisplay(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: 0.3,
  );

  /// Display Medium - For section headers
  static TextStyle displayMedium = GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: 0.3,
  );

  /// Display Small - For card titles
  static TextStyle displaySmall = GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: 0.3,
  );

  // ============================================================================
  // Headline Styles (Medium, Emphasis)
  // ============================================================================

  /// Headline Large - Gold accent
  static TextStyle headlineLarge = GoogleFonts.playfairDisplay(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.accentGold,
    height: 1.3,
    letterSpacing: 0.3,
  );

  /// Headline Medium
  static TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.3,
  );

  /// Headline Small
  static TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.3,
  );

  // ============================================================================
  // Title Styles
  // ============================================================================

  /// Title Large
  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Title Medium
  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Title Small
  static TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // ============================================================================
  // Body Styles (Regular Content)
  // ============================================================================

  /// Body Large
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  /// Body Medium
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  /// Body Small
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
    height: 1.5,
  );

  // ============================================================================
  // Label Styles (Uppercase, Spaced)
  // ============================================================================

  /// Label Large - Gold accent
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.accentGold,
  );

  /// Label Medium
  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  /// Label Small
  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textTertiary,
  );

  // ============================================================================
  // Special Styles
  // ============================================================================

  /// Button text style
  static TextStyle button = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  /// Gold button text
  static TextStyle goldButton = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.backgroundDark,
  );

  /// Caption text
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
    height: 1.4,
  );

  /// Overline text (small, uppercase)
  static TextStyle overline = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.textTertiary,
  );

  // ============================================================================
  // Utility Methods
  // ============================================================================

  /// Apply gold color to any text style
  static TextStyle withGold(TextStyle style) {
    return style.copyWith(color: AppColors.accentGold);
  }

  /// Apply white color to any text style
  static TextStyle withWhite(TextStyle style) {
    return style.copyWith(color: AppColors.textPrimary);
  }

  /// Apply secondary color to any text style
  static TextStyle withSecondary(TextStyle style) {
    return style.copyWith(color: AppColors.textSecondary);
  }

  /// Apply bold weight to any text style
  static TextStyle withBold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.bold);
  }

  /// Apply semibold weight to any text style
  static TextStyle withSemiBold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w600);
  }
}
