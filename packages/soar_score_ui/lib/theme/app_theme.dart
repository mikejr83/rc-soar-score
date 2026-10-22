import 'package:flutter/material.dart';

import 'brand_colors.dart';
import 'brand_typography.dart';

/// Colour tokens that are not part of the brand palette: the high-viz amber
/// used as the Material tertiary role for timers, running contests and
/// warnings. The brand palette itself is [BrandColors].
abstract final class AppColors {
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

/// The RC Soar Score brand as a Material 3 theme: the cockpit palette
/// ([BrandColors]), the bundled fonts ([BrandFonts]) and the type scale
/// ([BrandTypography]).
///
/// Light follows the brand kit exactly. The kit defines no dark theme; dark
/// here keeps its night ground and paper text and lifts the orange to the
/// kit's on-dark accent so button labels stay readable.
abstract final class BrandTheme {
  static const double radius = 12;
  static const double buttonRadius = 8;

  static ThemeData get light => _theme(
    ColorScheme.fromSeed(
      seedColor: BrandColors.deepOrange,
      brightness: Brightness.light,
      primary: BrandColors.deepOrange,
      onPrimary: Colors.white,
      // Secondary is read as the "positive" tone by the contest app; keep
      // it the status success green rather than a second brand colour.
      secondary: AppStatusColors.successColorLightTheme,
      onSecondary: Colors.white,
      // Tonal buttons, selected rows and chips: the kit's neutral, not a
      // seed-derived orange tint ("one orange element per area").
      secondaryContainer: BrandColors.tableHead,
      onSecondaryContainer: BrandColors.ink,
      tertiary: AppColors.highVizAmber,
      tertiaryContainer: AppColors.amberContainerLight,
      onTertiaryContainer: AppColors.onAmberContainerLight,
      surface: BrandColors.paper,
      onSurface: BrandColors.ink,
      onSurfaceVariant: BrandColors.muted,
      surfaceContainerLowest: BrandColors.card,
      surfaceContainerHigh: BrandColors.tableHead,
      outline: BrandColors.muted,
      outlineVariant: BrandColors.hairline,
    ),
    cardElevation: 2,
  );

  static ThemeData get dark => _theme(
    ColorScheme.fromSeed(
      seedColor: BrandColors.deepOrange,
      brightness: Brightness.dark,
      primary: BrandColors.orangeOnDark,
      onPrimary: BrandColors.dialBlack,
      secondary: AppStatusColors.successColorDarkTheme,
      onSecondary: BrandColors.dialBlack,
      secondaryContainer: BrandColors.bezelCharcoal,
      onSecondaryContainer: BrandColors.paper,
      tertiary: AppColors.highVizAmber,
      tertiaryContainer: AppColors.amberContainerDark,
      onTertiaryContainer: AppColors.onAmberContainerDark,
      surface: BrandColors.nightGround,
      onSurface: BrandColors.paper,
      onSurfaceVariant: BrandColors.mutedOnDark,
      surfaceContainerLowest: BrandColors.dialBlack,
      outlineVariant: BrandColors.bezelCharcoal,
    ),
    cardElevation: 1,
  );

  static ThemeData _theme(ColorScheme scheme, {required double cardElevation}) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    );
    return base.copyWith(
      textTheme: BrandTypography.textTheme(base.textTheme),
      cardTheme: CardThemeData(
        elevation: cardElevation,
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: shape),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(shape: shape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: shape),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: shape),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}

/// Theme of the contest administration app. Per-app differentiation goes
/// here, on top of [BrandTheme].
abstract final class ContestAppTheme {
  static ThemeData get lightTheme => BrandTheme.light;
  static ThemeData get darkTheme => BrandTheme.dark;
}

/// Theme of the participant self-scoring app.
abstract final class SelfScoreAppTheme {
  static ThemeData get lightTheme => BrandTheme.light;
  static ThemeData get darkTheme => BrandTheme.dark;
}

/// Theme of the public results site.
abstract final class PublicAppTheme {
  static ThemeData get lightTheme => BrandTheme.light;
  static ThemeData get darkTheme => BrandTheme.dark;
}
