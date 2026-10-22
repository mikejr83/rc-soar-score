import 'package:flutter/material.dart';

/// The cockpit palette from the RC Soar Score brand kit.
///
/// Charcoal and black from the instrument panel, one orange from the
/// elapsed-time pie. Orange should feel rare: one orange element per area of a
/// screen. [brandOrange] is for graphics and large headings only (white on it
/// is 4.0:1); anything with small text on it uses [deepOrange].
abstract final class BrandColors {
  /// The pie and the target ring. Graphics, progress bars, headings 24px+.
  static const Color brandOrange = Color(0xFFE8420C);

  /// Buttons, chips and orange links. White text passes at 6.0:1.
  static const Color deepOrange = Color(0xFFB83300);

  /// Hover state of [deepOrange].
  static const Color deepOrangeHover = Color(0xFF9E2C00);

  /// Orange accent on dark grounds (links, focus rings).
  static const Color orangeOnDark = Color(0xFFFF6A33);

  /// The square bezel and the target's outer ring. Logo and illustration.
  static const Color bezelCharcoal = Color(0xFF4A4643);

  /// The dial face, screws and the target's black ring.
  static const Color dialBlack = Color(0xFF0C0B0B);

  /// Text and the wordmark on light grounds.
  static const Color ink = Color(0xFF201E1D);

  /// Dark backgrounds: the app icon, banners, dark-mode surfaces.
  static const Color nightGround = Color(0xFF1C1B1A);

  /// Light backgrounds, the glider and ticks, text on dark.
  static const Color paper = Color(0xFFF3F2F2);

  /// Cards on paper.
  static const Color card = Color(0xFFFFFFFF);

  /// Secondary text on light: dates, venues, captions.
  static const Color muted = Color(0xFF605D5D);

  /// Secondary text on dark.
  static const Color mutedOnDark = Color(0xFFB8B3AD);

  /// Borders and dividers on light.
  static const Color hairline = Color(0xFFD6D2CC);

  /// Table header rows on light.
  static const Color tableHead = Color(0xFFE8E4DC);
}
