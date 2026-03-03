import 'package:flutter/material.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';

/// Glass Button
/// Kept for compatibility; rendered in a minimal style.
class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isGold;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isGold = false,
    this.borderRadius = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isGold) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGold,
          foregroundColor: Colors.white,
          elevation: 0,
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(text, style: AppTextStyles.goldButton),
                ],
              )
            : Text(text, style: AppTextStyles.goldButton),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariant
            : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        text,
                        style: AppTextStyles.button.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  )
                : Text(
                    text,
                    style: AppTextStyles.button.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Icon Glass Button
/// Circular glass button with icon
class IconGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final bool isGold;

  const IconGlassButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 40,
    this.isGold = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isGold) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.accentGold,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.accentGoldDark),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Center(
              child: Icon(icon, color: Colors.white, size: size * 0.5),
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariant
            : AppColors.surfaceVariantLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onSurface,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
