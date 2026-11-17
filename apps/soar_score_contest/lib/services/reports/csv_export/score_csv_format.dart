import 'score_export_source.dart';

/// One way of writing the contest's results as a CSV. The engine is
/// format-driven: a format turns the normalized source into rows, and a new
/// target (a GliderScore file, an import format) is a new class of this type
/// with no engine change.
abstract class ScoreCsvFormat {
  const ScoreCsvFormat();

  /// The format's name, shown to the director.
  String get name;

  /// The file's extension, without the dot.
  String get fileExtension;

  /// The rows to export: a header first, then the data. A `null` cell is an
  /// empty cell, which the builder keeps distinct from a real `0`.
  List<List<String?>> build(ScoreExportSource source);
}
