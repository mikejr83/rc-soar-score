import 'package:flutter/material.dart';

/// The sheet is a paper document, not part of the app theme: black on white in
/// a neutral face whatever the theme, dark included, so the screen is a faithful
/// preview and a black-and-white laser printer loses nothing.
abstract final class PaperStyle {
  static const Color paper = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF000000);

  /// Table rules and dropped-round shading: grey that prints as grey.
  static const Color rule = Color(0xFFBDBDBD);
  static const Color shade = Color(0xFFE8E8E8);

  static const List<String> fontFallback = [
    'Noto Sans',
    'Arial',
    'Helvetica',
    'Segoe UI',
  ];

  /// The grey behind the pages: part of the app chrome, so it follows the
  /// theme.
  static Color backdrop(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0xFF2A2E33)
      : const Color(0xFFD9DCE0);

  /// A light theme with the sheet's face, so widgets inside a page never pick
  /// up the app's colours.
  static ThemeData theme() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: ink,
      onPrimary: paper,
      surface: paper,
      onSurface: ink,
    ),
    fontFamilyFallback: fontFallback,
    scaffoldBackgroundColor: paper,
    dividerColor: rule,
  );

  static const TextStyle body = TextStyle(
    color: ink,
    fontSize: 12,
    height: 1.25,
    fontFamilyFallback: fontFallback,
    decoration: TextDecoration.none,
  );
}
