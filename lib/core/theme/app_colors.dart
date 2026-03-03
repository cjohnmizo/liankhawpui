import 'package:flutter/material.dart';

/// Core color tokens used across the app.
/// Names are preserved for compatibility with existing screens.
class AppColors {
  AppColors._();

  // Brand / primary
  static const Color primaryNavy = Color(0xFF1F2937);
  static const Color primaryNavyDark = Color(0xFF111827);
  static const Color primaryNavyLight = Color(0xFF374151);
  static const Color primaryNavyLighter = Color(0xFF4B5563);

  // Accent (kept key names for compatibility)
  static const Color accentGold = Color(0xFF2563EB);
  static const Color accentGoldLight = Color(0xFF60A5FA);
  static const Color accentGoldDark = Color(0xFF1D4ED8);
  static const Color accentBeige = Color(0xFFE5E7EB);
  static const Color accentBeigeLight = Color(0xFFF3F4F6);

  // Dark surfaces
  static const Color backgroundDark = Color(0xFF0B1220);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color surfaceVariant = Color(0xFF1F2937);
  static const Color surfaceCard = Color(0xFF101827);

  // Light surfaces
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color surfaceCardLight = Color(0xFFFFFFFF);

  // Glass-ish helpers used by legacy widgets
  static Color get glassSurface => surfaceVariant.withValues(alpha: 0.88);
  static Color get glassSurfaceLight => surfaceLight.withValues(alpha: 0.92);
  static Color get glassBorder =>
      const Color(0xFFCBD5E1).withValues(alpha: 0.55);
  static Color get glassBorderLight =>
      const Color(0xFFE2E8F0).withValues(alpha: 0.32);
  static Color get glassBorderLightMode => const Color(0xFFCBD5E1);
  static Color get glassShadow => Colors.black.withValues(alpha: 0.14);
  static Color get glassShadowLight => Colors.black.withValues(alpha: 0.06);

  // Text colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFF64748B);
  static const Color textGold = accentGold;

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF334155);
  static const Color textTertiaryLight = Color(0xFF64748B);
  static const Color textDisabledLight = Color(0xFF94A3B8);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);

  // Gradients kept for compatibility but intentionally subtle/minimal
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryNavyDark, primaryNavy],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGoldDark, accentGold],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundDark, backgroundDark],
  );

  static LinearGradient get glassGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      surfaceVariant.withValues(alpha: 0.9),
      surfaceVariant.withValues(alpha: 0.82),
    ],
  );

  static Color get goldGlow => accentGold.withValues(alpha: 0.22);
  static Color get navyGlow => primaryNavy.withValues(alpha: 0.18);
}
