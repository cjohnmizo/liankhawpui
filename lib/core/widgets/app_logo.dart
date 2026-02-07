import 'package:flutter/material.dart';
import 'package:liankhawpui/core/config/app_assets.dart';

/// Reusable App Logo Widget
///
/// Displays the Liankhawpui app logo (Android launcher icon with transparent background).
/// This widget can be used throughout the app for consistent branding.
class AppLogo extends StatelessWidget {
  /// Size of the logo
  final double size;

  /// Optional color filter to apply to the logo
  final Color? color;

  /// Fit mode for the image
  final BoxFit fit;

  /// Optional semantic label for accessibility
  final String? semanticLabel;

  const AppLogo({
    super.key,
    this.size = 48.0,
    this.color,
    this.fit = BoxFit.contain,
    this.semanticLabel = 'Liankhawpui Logo',
  });

  /// Small logo (32x32)
  const AppLogo.small({
    super.key,
    this.color,
    this.fit = BoxFit.contain,
    this.semanticLabel = 'Liankhawpui Logo',
  }) : size = 32.0;

  /// Medium logo (48x48) - Default
  const AppLogo.medium({
    super.key,
    this.color,
    this.fit = BoxFit.contain,
    this.semanticLabel = 'Liankhawpui Logo',
  }) : size = 48.0;

  /// Large logo (96x96)
  const AppLogo.large({
    super.key,
    this.color,
    this.fit = BoxFit.contain,
    this.semanticLabel = 'Liankhawpui Logo',
  }) : size = 96.0;

  /// Extra large logo (144x144)
  const AppLogo.extraLarge({
    super.key,
    this.color,
    this.fit = BoxFit.contain,
    this.semanticLabel = 'Liankhawpui Logo',
  }) : size = 144.0;

  /// Hero logo for splash screens (256x256)
  const AppLogo.hero({
    super.key,
    this.color,
    this.fit = BoxFit.contain,
    this.semanticLabel = 'Liankhawpui Logo',
  }) : size = 256.0;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.appLogo,
      width: size,
      height: size,
      fit: fit,
      color: color,
      semanticLabel: semanticLabel,
      // Prevent logo from being too small on larger screens
      filterQuality: FilterQuality.high,
    );
  }
}

/// Circular App Logo Widget
///
/// Displays the app logo in a circular container with optional background.
class CircularAppLogo extends StatelessWidget {
  /// Size of the circular logo
  final double size;

  /// Background color of the circle (null for transparent)
  final Color? backgroundColor;

  /// Optional border color
  final Color? borderColor;

  /// Border width
  final double borderWidth;

  /// Padding inside the circle
  final double padding;

  const CircularAppLogo({
    super.key,
    this.size = 64.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0.0,
    this.padding = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: borderWidth > 0 && borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      padding: EdgeInsets.all(padding),
      child: Image.asset(
        AppAssets.appLogo,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
