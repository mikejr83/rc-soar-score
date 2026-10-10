import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary Seed Color: Deep Sky Blue
  static const Color skyBlueSeed = Color(0xFF006399);
  static const Color primaryColor = Color(0xFF006399);
  static const Color secondaryColor = Color(0xFF2D6A4F);
  static const Color surfaceColor = Color(0xFFF8FAFC);
  // Custom High-Viz Accent for Timers & Max Scores
  static const Color highVizAmber = Color(0xFFD97706);
  // Amber containers for warnings: the accent itself is below 4.5:1 as text.
  static const Color amberContainerLight = Color(0xFFFFDDB8);
  static const Color onAmberContainerLight = Color(0xFF2C1600);
  static const Color amberContainerDark = Color(0xFF653E00);
  static const Color onAmberContainerDark = Color(0xFFFFDDB8);
}

abstract final class AppStatusColors {
  static const Color successColorDarkTheme = Color(0xFF95D4B3);
  static const Color successColorLightTheme = Color(0xFF2D6A4F);
  static const Color warningColorDarkTheme = Color(0xFFFFB870);
  static const Color warningColorLightTheme = Color(0xFF8A5100);

  static const Color successContainerDarkTheme = Color(0xFF0F5138);
  static const Color successContainerLightTheme = Color(0xFFB1F1CE);

  static const Color onSuccessContainerDarkTheme = Color(0xFFB1F1CE);
  static const Color onSuccessContainerLightTheme = Color(0xFF002113);

  static Color getWarning(bool dark) {
    return dark ? warningColorDarkTheme : warningColorLightTheme;
  }

  static Color getSuccess(bool dark) {
    return dark ? successColorDarkTheme : successColorLightTheme;
  }

  static Color getSuccessContainer(bool dark) {
    return dark ? successContainerDarkTheme : successContainerLightTheme;
  }
  
  static Color getOnSuccessContainer(bool dark) {
    return dark ? onSuccessContainerDarkTheme : onSuccessContainerLightTheme;
  }
}

/// Baseline Material 3 theme for the RC Soar Score Contest Management app.
///
/// Single source of truth for theming: `MaterialApp` in `app.dart` takes its
/// themes exclusively from this file (no inline `MaterialApp(theme:)` values).
abstract final class ContestAppTheme {
  static const double _defaultBorderRadius = 12;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.skyBlueSeed,
        brightness: Brightness.light,
        primary: AppColors.primaryColor,
        secondary: AppColors.secondaryColor,
        tertiary: AppColors.highVizAmber,
        tertiaryContainer: AppColors.amberContainerLight,
        onTertiaryContainer: AppColors.onAmberContainerLight,
        surface: AppColors.surfaceColor,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_defaultBorderRadius),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 3,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.skyBlueSeed,
        brightness: Brightness.dark,
        tertiary: AppColors.highVizAmber,
        tertiaryContainer: AppColors.amberContainerDark,
        onTertiaryContainer: AppColors.onAmberContainerDark,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_defaultBorderRadius),
        ),
      ),
    );
  }
}

abstract final class SelfScoreAppTheme {
  static const double _defaultBorderRadius = 12;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.skyBlueSeed,
        brightness: Brightness.light,
        primary: AppColors.primaryColor,
        secondary: AppColors.secondaryColor,
        tertiary: AppColors.highVizAmber,
        tertiaryContainer: AppColors.amberContainerLight,
        onTertiaryContainer: AppColors.onAmberContainerLight,
        surface: AppColors.surfaceColor,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_defaultBorderRadius),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 3,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.skyBlueSeed,
        brightness: Brightness.dark,
        tertiary: AppColors.highVizAmber,
        tertiaryContainer: AppColors.amberContainerDark,
        onTertiaryContainer: AppColors.onAmberContainerDark,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_defaultBorderRadius),
        ),
      ),
    );
  }
}

abstract final class PublicAppTheme {
  static const double _defaultBorderRadius = 12;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.skyBlueSeed,
        brightness: Brightness.light,
        primary: AppColors.primaryColor,
        secondary: AppColors.secondaryColor,
        tertiary: AppColors.highVizAmber,
        tertiaryContainer: AppColors.amberContainerLight,
        onTertiaryContainer: AppColors.onAmberContainerLight,
        surface: AppColors.surfaceColor,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_defaultBorderRadius),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 3,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.skyBlueSeed,
        brightness: Brightness.dark,
        tertiary: AppColors.highVizAmber,
        tertiaryContainer: AppColors.amberContainerDark,
        onTertiaryContainer: AppColors.onAmberContainerDark,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_defaultBorderRadius),
        ),
      ),
    );
  }
}