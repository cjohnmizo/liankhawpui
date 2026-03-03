import 'package:flutter/material.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';

/// Compatibility wrapper used across screens.
/// Kept as `GlassCard` name, but rendered as a clean minimal surface.
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
    this.opacity = 1,
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
    final bgColor = isDark ? AppColors.surfaceCard : AppColors.surfaceCardLight;

    final borderColor = isPremium
        ? AppColors.accentGold.withValues(alpha: 0.28)
        : (withGoldBorder
              ? AppColors.glassBorder
              : AppColors.glassBorder.withValues(alpha: 0.75));

    final card = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: opacity.clamp(0, 1).toDouble()),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.glassShadow : AppColors.glassShadowLight,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: card,
    );
  }
}

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
    return GlassCard(
      borderRadius: borderRadius,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      isPremium: true,
      onTap: onTap,
      child: child,
    );
  }
}

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
    return GlassCard(
      borderRadius: borderRadius,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(12),
      withGoldBorder: false,
      onTap: onTap,
      child: child,
    );
  }
}
