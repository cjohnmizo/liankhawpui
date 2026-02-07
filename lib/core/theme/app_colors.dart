import 'package:flutter/material.dart';

/// App Color Palette
/// Based on t_logo.png colors: Deep Navy Blue + Luxurious Gold
class AppColors {
  AppColors._(); // Private constructor

  // ============================================================================
  // Primary Colors (Navy Blue from Logo)
  // ============================================================================

  /// Deep navy blue - Primary brand color (Slightly more saturated)
  static const Color primaryNavy = Color(0xFF151B54); // Deep Royal Blue
  static const Color primaryNavyDark = Color(0xFF0A0E2E); // Almost Black Blue
  static const Color primaryNavyLight = Color(
    0xFF304FFE,
  ); // Vibrant accent blue
  static const Color primaryNavyLighter = Color(0xFF536DFE);

  // ============================================================================
  // Accent Colors (Gold from Logo)
  // ============================================================================

  /// Luxurious gold - Premium accent color (More metallic, less yellow)
  static const Color accentGold = Color(0xFFC5A059); // Metallic Gold
  static const Color accentGoldLight = Color(0xFFE6C888); // Champagne
  static const Color accentGoldDark = Color(0xFF8D7132); // Bronze

  /// Beige/Cream from logo highlights
  static const Color accentBeige = Color(0xFFF3E5AB); // Vanilla
  static const Color accentBeigeLight = Color(0xFFFFF8E1);

  // ============================================================================
  // Dark Mode Backgrounds
  // ============================================================================

  /// Very dark background (Neutral Black)
  static const Color backgroundDark = Color(0xFF000000);

  /// Dark surface (Neutral Dark Grey)
  static const Color surfaceDark = Color(0xFF121212);

  /// Lighter surface variant (Neutral Grey)
  static const Color surfaceVariant = Color(0xFF1E1E1E);

  /// Card surface -> Pure Black for high contrast minimal glass
  static const Color surfaceCard = Color(0xFF000000);

  // ============================================================================
  // Light Mode Backgrounds
  // ============================================================================

  /// Light background - soft white/grey
  static const Color backgroundLight = Color(0xFFFAFAFA);

  /// Light surface - pure white
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Light surface variant - subtle grey/blue tint
  static const Color surfaceVariantLight = Color(0xFFEEF2F6);

  /// Light card surface
  static const Color surfaceCardLight = Color(0xFFFFFFFF);

  // ============================================================================
  // Glass Effect Colors
  // ============================================================================

  /// Glass surface with opacity (use with BackdropFilter) - Dark mode
  static Color get glassSurface => surfaceVariant.withValues(alpha: 0.6);

  /// Glass surface for light mode
  static Color get glassSurfaceLight => surfaceLight.withValues(alpha: 0.7);

  /// Glass border - subtle gold tint
  static Color get glassBorder => accentGold.withValues(alpha: 0.15);

  /// Glass border light variant
  static Color get glassBorderLight => Colors.white.withValues(alpha: 0.05);

  /// Glass border for light mode
  static Color get glassBorderLightMode => primaryNavy.withValues(alpha: 0.08);

  /// Glass shadow
  static Color get glassShadow => Colors.black.withValues(alpha: 0.5);

  /// Glass shadow for light mode
  static Color get glassShadowLight =>
      const Color(0xFF9EA3B8).withValues(alpha: 0.2);

  // ============================================================================
  // Text Colors (Dark Mode)
  // ============================================================================

  /// Primary text on dark background
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text (slightly dimmed)
  static const Color textSecondary = Color(0xFFB0B3C5);

  /// Tertiary text (more dimmed)
  static const Color textTertiary = Color(0xFF7E84A3);

  /// Disabled text
  static const Color textDisabled = Color(0xFF555B7D);

  /// Gold text for highlights
  static const Color textGold = accentGold;

  // ============================================================================
  // Text Colors (Light Mode)
  // ============================================================================

  /// Primary text on light background
  static const Color textPrimaryLight = Color(0xFF121212);

  /// Secondary text (light mode)
  static const Color textSecondaryLight = Color(0xFF424242);

  /// Tertiary text (light mode)
  static const Color textTertiaryLight = Color(0xFF757575);

  /// Disabled text (light mode)
  static const Color textDisabledLight = Color(0xFFBDBDBD);

  // ============================================================================
  // Semantic Colors
  // ============================================================================

  /// Success color
  static const Color success = Color(0xFF00C853);

  /// Warning color
  static const Color warning = Color(0xFFFFAB00);

  /// Error color
  static const Color error = Color(0xFFD50000);

  /// Info color (light blue)
  static const Color info = Color(0xFF2962FF);

  // ============================================================================
  // Gradients
  // ============================================================================

  /// Primary navy gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryNavy, primaryNavyLight],
  );

  /// Gold accent gradient
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGoldDark, accentGold, accentGoldLight],
  );

  /// Dark background gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundDark, surfaceDark],
  );

  /// Glass surface gradient
  static LinearGradient get glassGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      surfaceVariant.withValues(alpha: 0.8),
      surfaceVariant.withValues(alpha: 0.6),
    ],
  );

  // ============================================================================
  // Glow Effects
  // ============================================================================

  /// Gold glow color for premium elements
  static Color get goldGlow => accentGold.withValues(alpha: 0.5);

  /// Navy glow for primary elements
  static Color get navyGlow => primaryNavy.withValues(alpha: 0.5);
}
