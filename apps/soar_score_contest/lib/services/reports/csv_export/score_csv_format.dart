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

  /// A text cell made safe for a spreadsheet: a leading apostrophe when it
  /// starts with a formula or control character.
  static String harden(String text) {
    if (text.isEmpty) {
      return text;
    }
    final first = text.codeUnitAt(0);
    if (first == 0x3D || // =
        first == 0x2B || // +
        first == 0x2D || // -
        first == 0x40 || // @
        first == 0x09 || // tab
        first ==
            0x0D // \r
            ) {
      return "'$text";
    }
    return text;
  }
}
