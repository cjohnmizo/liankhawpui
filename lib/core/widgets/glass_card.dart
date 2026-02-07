import 'package:flutter/material.dart';
import 'package:liankhawpui/core/theme/glass_styles.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';

/// Glass Card Widget
/// Reusable frosted glass container with blur effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double opacity;
  final bool withGoldBorder;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool isPremium;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.opacity = 0.7,
    this.withGoldBorder = true,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceCard
        : AppColors.surfaceCardLight;

    final decoration = isPremium
        ? GlassStyles.premiumGlassCard(
            borderRadius: borderRadius,
            opacity: opacity,
            color: surfaceColor,
          )
        : GlassStyles.glassCard(
            borderRadius: borderRadius,
            opacity: opacity,
            withGoldBorder: withGoldBorder,
            customColor: surfaceColor,
          );

    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: decoration,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      );
    }

    return card;
  }
}

/// Elevated Glass Card (more prominent)
class ElevatedGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const ElevatedGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceCard
        : AppColors.surfaceCardLight;

    Widget card = Container(
      margin: margin,
      decoration: GlassStyles.elevatedGlassCard(
        borderRadius: borderRadius,
        color: surfaceColor,
      ),
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      );
    }

    return card;
  }
}

/// Subtle Glass Card (less prominent)
class SubtleGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const SubtleGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 10,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceCard
        : AppColors.surfaceCardLight;

    Widget card = Container(
      margin: margin,
      decoration: GlassStyles.subtleGlass(
        borderRadius: borderRadius,
        color: surfaceColor,
      ),
      child: Container(
        padding: padding ?? const EdgeInsets.all(12),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      );
    }

    return card;
  }
}
