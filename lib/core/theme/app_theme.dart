import 'package:flutter/material.dart';
import 'package:liankhawpui/core/theme/app_colors.dart';
import 'package:liankhawpui/core/theme/text_styles.dart';

class AppTheme {
  AppTheme._();

  static LinearGradient get primaryGradient => AppColors.primaryGradient;
  static LinearGradient get secondaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentGoldDark, AppColors.accentGold],
  );
  static LinearGradient get accentGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryNavy, AppColors.primaryNavyLight],
  );
  static LinearGradient get goldGradient => AppColors.goldGradient;
  static LinearGradient get backgroundGradient => AppColors.backgroundGradient;

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final base = ColorScheme.fromSeed(
      seedColor: AppColors.accentGold,
      brightness: brightness,
    );
    final colorScheme = base.copyWith(
      primary: AppColors.accentGold,
      onPrimary: Colors.white,
      secondary: AppColors.primaryNavy,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      onSurface: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
      surfaceContainerHighest: isDark
          ? AppColors.surfaceVariant
          : AppColors.surfaceVariantLight,
    );

    final textTheme = TextTheme(
      displayLarge: isDark
          ? AppTextStyles.displayLarge
          : AppTextStyles.displayLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
      displayMedium: isDark
          ? AppTextStyles.displayMedium
          : AppTextStyles.displayMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
      displaySmall: isDark
          ? AppTextStyles.displaySmall
          : AppTextStyles.displaySmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
      headlineLarge: isDark
          ? AppTextStyles.headlineLarge
          : AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
      headlineMedium: isDark
          ? AppTextStyles.headlineMedium
          : AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
      headlineSmall: isDark
          ? AppTextStyles.headlineSmall
          : AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
      titleLarge: isDark
          ? AppTextStyles.titleLarge
          : AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
      titleMedium: isDark
          ? AppTextStyles.titleMedium
          : AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
      titleSmall: isDark
          ? AppTextStyles.titleSmall
          : AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
      bodyLarge: isDark
          ? AppTextStyles.bodyLarge
          : AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
      bodyMedium: isDark
          ? AppTextStyles.bodyMedium
          : AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
      bodySmall: isDark
          ? AppTextStyles.bodySmall
          : AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
            ),
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: isDark
          ? AppTextStyles.labelMedium
          : AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
      labelSmall: isDark
          ? AppTextStyles.labelSmall
          : AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiaryLight,
            ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.surfaceCard : AppColors.surfaceCardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.surfaceVariant
            : AppColors.surfaceVariantLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentGold, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.accentGold,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.glassBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          foregroundColor: colorScheme.onSurface,
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentGold,
          textStyle: AppTextStyles.button,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentGold,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.surfaceVariant
            : AppColors.surfaceVariantLight,
        selectedColor: AppColors.accentGold.withValues(alpha: 0.14),
        side: BorderSide(color: AppColors.glassBorder),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        elevation: 0,
        selectedItemColor: AppColors.accentGold,
        unselectedItemColor: isDark
            ? AppColors.textTertiary
            : AppColors.textTertiaryLight,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isDark
            ? AppColors.textSecondary
            : AppColors.textSecondaryLight,
        textColor: colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentGold;
          }
          return isDark ? AppColors.textTertiary : AppColors.textTertiaryLight;
        }),
      ),
    );
  }

  static List<BoxShadow> elevatedShadow(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.2),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
