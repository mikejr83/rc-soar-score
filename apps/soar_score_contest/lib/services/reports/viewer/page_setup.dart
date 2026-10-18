import 'dart:ui';

/// The paper a report is laid out for.
enum PaperSize {
  letter('Letter', 816, 1056),
  a4('A4', 794, 1123);

  const PaperSize(this.label, this._width, this._height);

  final String label;

  /// The short and long sides in logical pixels (96 to the inch).
  final double _width;
  final double _height;

  /// Countries whose standard paper is Letter; everywhere else uses A4.
  static const _letterCountries = {
    'US',
    'CA',
    'MX',
    'PH',
    'CL',
    'CO',
    'VE',
    'PR',
  };

  /// The paper to start with for [locale]. Page setup is not stored, so every
  /// session starts from this.
  static PaperSize forLocale(Locale locale) =>
      _letterCountries.contains(locale.countryCode) ? letter : a4;

  /// The locale-based explanation shown under the paper choice.
  String defaultNote(Locale locale) => this == forLocale(locale)
      ? '$label is the default for your locale.'
      : '${forLocale(locale).label} is the default for your locale.';
}

enum PageOrientation {
  portrait('Portrait'),
  landscape('Landscape');

  const PageOrientation(this.label);

  final String label;
}

/// Paper and orientation of a printed report.
class PageSetup {
  const PageSetup(this.paper, this.orientation);

  final PaperSize paper;
  final PageOrientation orientation;

  double get width =>
      orientation == PageOrientation.landscape ? paper._height : paper._width;

  double get height =>
      orientation == PageOrientation.landscape ? paper._width : paper._height;

  Size get size => Size(width, height);

  /// "Letter · Landscape".
  String get label => '${paper.label} · ${orientation.label}';

  @override
  bool operator ==(Object other) =>
      other is PageSetup &&
      other.paper == paper &&
      other.orientation == orientation;

  @override
  int get hashCode => Object.hash(paper, orientation);
}
