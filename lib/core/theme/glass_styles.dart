import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';

/// Glassmorphism Style Utilities
/// Provides reusable glass effect decorations and styles
class GlassStyles {
  GlassStyles._(); // Private constructor

  // ============================================================================
  // Glass Decorations
  // ============================================================================

  /// Standard glass card decoration
  static BoxDecoration glassCard({
    double borderRadius = 12,
    double opacity = 0.7,
    bool withGoldBorder = true,
    Color? customColor,
  }) {
    return BoxDecoration(
      color: (customColor ?? AppColors.surfaceCard).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: withGoldBorder
            ? AppColors.glassBorder
            : AppColors.glassBorderLight,
        width: 0.5, // Minimal border
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.glassShadow,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Premium glass card with gold accent
  static BoxDecoration premiumGlassCard({
    double borderRadius = 12,
    double opacity = 0.75,
    Color? color,
  }) {
    return BoxDecoration(
      color: (color ?? AppColors.surfaceCard).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: AppColors.accentGold.withValues(alpha: 0.2), // Subtle gold
        width: 0.5, // Minimal border
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.glassShadow,
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  /// Elevated glass card (more prominent)
  static BoxDecoration elevatedGlassCard({
    double borderRadius = 12,
    double opacity = 0.8,
    Color? color,
  }) {
    return BoxDecoration(
      color: (color ?? AppColors.surfaceCard).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: AppColors.glassBorder, width: 0.5),
      boxShadow: [
        BoxShadow(
          color: AppColors.glassShadow,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Subtle glass decoration (less prominent)
  static BoxDecoration subtleGlass({
    double borderRadius = 10,
    double opacity = 0.5,
    Color? color,
  }) {
    return BoxDecoration(
      color: (color ?? AppColors.surfaceCard).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: AppColors.glassBorderLight, width: 0.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // ============================================================================
  // Blur Filters (Minimalistic - Reduced for Performance)
  // ============================================================================

  /// Standard blur for glass effect
  static ImageFilter get standardBlur => ImageFilter.blur(sigmaX: 5, sigmaY: 5);

  /// Heavy blur for prominent glass
  static ImageFilter get heavyBlur => ImageFilter.blur(sigmaX: 8, sigmaY: 8);

  /// Light blur for subtle glass
  static ImageFilter get lightBlur => ImageFilter.blur(sigmaX: 3, sigmaY: 3);

  // ============================================================================
  // Shadows
  // ============================================================================

  /// Premium shadow with gold glow
  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: AppColors.glassShadow,
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  /// Elevated shadow
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: AppColors.glassShadow,
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Subtle shadow
  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// Gold glow shadow
  static List<BoxShadow> get goldGlowShadow => [
    BoxShadow(
      color: AppColors.goldGlow,
      blurRadius: 12,
      offset: const Offset(0, 0),
    ),
  ];

  // ============================================================================
  // Button Styles
  // ============================================================================

  /// Gold accent button decoration
  static BoxDecoration goldButton({double borderRadius = 12}) {
    return BoxDecoration(
      gradient: AppColors.goldGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: AppColors.goldGlow,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Glass button decoration
  static BoxDecoration glassButton({double borderRadius = 12}) {
    return BoxDecoration(
      color: AppColors.surfaceVariant.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: AppColors.glassBorder, width: 1),
      boxShadow: subtleShadow,
    );
  }

  // ============================================================================
  // Dividers
  // ============================================================================

  /// Gold accent divider
  static Widget goldDivider({
    double height = 1,
    double indent = 0,
    double endIndent = 0,
  }) {
    return Container(
      height: height,
      margin: EdgeInsets.only(left: indent, right: endIndent),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.accentGold.withValues(alpha: 0.5),
            AppColors.accentGold,
            AppColors.accentGold.withValues(alpha: 0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  /// Subtle glass divider
  static Widget glassDivider({
    double height = 1,
    double indent = 0,
    double endIndent = 0,
  }) {
    return Container(
      height: height,
      margin: EdgeInsets.only(left: indent, right: endIndent),
      color: AppColors.glassBorderLight,
    );
  }
}
