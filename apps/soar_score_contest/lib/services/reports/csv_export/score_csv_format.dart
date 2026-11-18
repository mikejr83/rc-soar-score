import 'score_export_source.dart';

/// One way of writing the contest's results as a CSV. The engine is
/// format-driven: a format turns the normalized source into rows, and a new
/// target (a GliderScore file, an import format) is a new class of this type
/// with no engine change.
abstract class ScoreCsvFormat {
  const ScoreCsvFormat({this.writeBom = true, this.hardenText = true});

  /// Write a UTF-8 BOM so Excel on Windows reads the file as UTF-8 instead of
  /// ANSI (a BOM-less file mangles non-ASCII names). Off for an import target
  /// that rejects a BOM.
  final bool writeBom;

  /// Guard text cells against spreadsheet formula injection: a text value that
  /// starts with a character a spreadsheet treats as a formula or control
  /// gets a leading apostrophe. Never applied to numeric cells or the header.
  /// Off for an import target that needs the raw value.
  final bool hardenText;

  /// The format's name, shown to the director.
  String get name;

  /// The file's extension, without the dot.
  String get fileExtension;

  /// The rows to export: a header first, then the data. A `null` cell is an
  /// empty cell, which the builder keeps distinct from a real `0`.
  List<List<String?>> build(ScoreExportSource source);

  /// The characters a spreadsheet treats as the start of a formula or a
  /// control character: `=`, `+`, `-`, `@`, tab and CR.
  static const _risky = {0x3D, 0x2B, 0x2D, 0x40, 0x09, 0x0D};

  /// A text cell made safe for a spreadsheet: a leading apostrophe when it
  /// starts with a formula or control character. The apostrophe is shown
  /// literally by Excel and LibreOffice (a CSV import does not treat it as
  /// Excel's hidden text prefix); that is the cost of guarding against
  /// formula injection, and the `hardenText` flag can be turned off for an
  /// import target that wants the raw value.
  static String harden(String text) {
    if (text.isEmpty) {
      return text;
    }
    return _risky.contains(text.codeUnitAt(0)) ? "'$text" : text;
  }
}
