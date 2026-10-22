import 'package:flutter/material.dart';

/// The three brand fonts, bundled with this package (see `pubspec.yaml`).
///
/// Flutter resolves a font shipped by a dependency only through the
/// `packages/<package>/<family>` name, so use these constants rather than the
/// bare family names.
abstract final class BrandFonts {
  static const String _pkg = 'packages/soar_score_ui/';

  /// Headings: page titles, contest names, section headings. Weights 700, 800.
  static const String display = '${_pkg}League Spartan';

  /// Body copy, tables, buttons and every number. Weights 400 to 800.
  static const String body = '${_pkg}Archivo';

  /// Stencil accent, sparingly: one number or short word per screen.
  static const String accent = '${_pkg}Saira Stencil One';
}

/// The brand type scale as a Material [TextTheme], plus the styles that have
/// no Material slot.
abstract final class BrandTypography {
  /// Scores and any column of numbers: tabular figures so they line up.
  static const TextStyle numbers = TextStyle(
    fontFamily: BrandFonts.body,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// A place or round splash ("1st", "ROUND 4"). Never sentences.
  static const TextStyle stencilHero = TextStyle(
    fontFamily: BrandFonts.accent,
    fontSize: 64,
    height: 1,
    fontWeight: FontWeight.w400,
  );

  /// Small uppercase label with wide tracking ("RC GLIDER CONTEST SCORING").
  static const TextStyle eyebrow = TextStyle(
    fontFamily: BrandFonts.body,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.18 * 12,
  );

  static const TextStyle _displayLarge = TextStyle(
    fontFamily: BrandFonts.display,
    fontSize: 48,
    height: 52 / 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.48,
  );
  static const TextStyle _headlineLarge = TextStyle(
    fontFamily: BrandFonts.display,
    fontSize: 32,
    height: 38 / 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.32,
  );
  static const TextStyle _headlineMedium = TextStyle(
    fontFamily: BrandFonts.display,
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle _titleLarge = TextStyle(
    fontFamily: BrandFonts.display,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle _bodyLarge = TextStyle(
    fontFamily: BrandFonts.body,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );

  /// Material text theme: League Spartan in the display, headline and title
  /// slots, Archivo everywhere else. Merged over the Material defaults so
  /// every slot keeps its colour and the slots the kit does not name keep
  /// Material's sizes in the body font.
  static TextTheme textTheme(TextTheme base) {
    final t = base.apply(fontFamily: BrandFonts.body);
    return t.copyWith(
      displayLarge: t.displayLarge!.merge(_displayLarge),
      displayMedium: t.displayMedium!.merge(
        _displayLarge.copyWith(fontSize: 40, height: 44 / 40),
      ),
      displaySmall: t.displaySmall!.merge(_headlineLarge),
      headlineLarge: t.headlineLarge!.merge(_headlineLarge),
      headlineMedium: t.headlineMedium!.merge(_headlineMedium),
      headlineSmall: t.headlineSmall!.merge(
        _headlineMedium.copyWith(fontSize: 20, height: 1.3),
      ),
      titleLarge: t.titleLarge!.merge(_titleLarge),
      bodyLarge: t.bodyLarge!.merge(_bodyLarge),
      labelSmall: t.labelSmall!.merge(eyebrow),
    );
  }
}
