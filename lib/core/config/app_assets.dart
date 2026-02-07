/// App Asset Constants
///
/// Centralized location for all asset paths used throughout the app.
/// This ensures consistency and makes it easy to update asset references.
class AppAssets {
  AppAssets._(); // Private constructor to prevent instantiation

  // ============================================================================
  // App Logo & Branding
  // ============================================================================

  /// Main app logo (transparent background, suitable for any theme)
  /// This is the primary logo used throughout the app
  static const String appLogo = 'assets/icon/t_logo.png';

  /// Dark theme logo (with dark background elements)
  static const String logoDark = 'assets/logo_dark.png';

  /// Light theme logo (with light background elements)
  static const String logoLight = 'assets/logo_light.png';

  // ============================================================================
  // Launcher Icons (for reference, not typically used in-app)
  // ============================================================================

  /// iOS App Icon (1024x1024, no alpha)
  static const String iosAppIcon = 'assets/icon/ios/AppIcon-1024.png';

  /// Android Launcher Foreground
  static const String androidIconForeground =
      'assets/icon/android/ic_launcher_foreground.png';

  /// Android Launcher Background
  static const String androidIconBackground =
      'assets/icon/android/ic_launcher_background.png';

  /// Play Store Icon (512x512)
  static const String playStoreIcon =
      'assets/icon/android/playstore-icon-512.png';

  // ============================================================================
  // Other Assets
  // ============================================================================

  /// Landscape/Banner image
  static const String landscape = 'assets/landscape.png';

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Get the appropriate logo based on theme brightness
  static String getLogoForTheme(bool isDark) {
    return isDark ? logoDark : logoLight;
  }
}
