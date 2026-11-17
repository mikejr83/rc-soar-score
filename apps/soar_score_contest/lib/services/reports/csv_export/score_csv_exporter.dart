import 'csv_builder.dart';
import 'csv_file_name.dart';
import 'save_csv_platform.dart' as platform;
import 'score_csv_format.dart';
import 'score_export_source.dart';

/// Saves a CSV file and answers the name written, or `null` when the director
/// cancelled. The web build downloads a blob; the native build uses the save
/// dialog. A test swaps in a recorder with no real IO.
typedef SaveCsvFile = Future<String?> Function(String fileName, String csv);

/// The engine's entry point: it turns a [ScoreExportSource] into a CSV in the
/// chosen [ScoreCsvFormat] and saves it. The save step is injected, mirroring
/// the `printDialog`/`saveFile` injection on the report printer, so a test
/// never writes a file.
class ScoreCsvExporter {
  ScoreCsvExporter({
    this.saveFile = platform.saveCsvFile,
    this.builder = const CsvBuilder(),
  });

  /// Writes the file and answers its name, or `null` when cancelled.
  final SaveCsvFile saveFile;

  final CsvBuilder builder;

  /// The CSV for [source] in [format]: a header, then the rows.
  String exportCsv(ScoreExportSource source, ScoreCsvFormat format) =>
      builder.build(format.build(source));

  /// Exports and saves [source] in [format], naming the file from the report
  /// and contest names and the format's extension. Answers the file name, or
  /// `null` when the director cancelled.
  Future<String?> saveCsv(
    ScoreExportSource source,
    ScoreCsvFormat format, {
    required String reportName,
  }) async {
    final name = csvFileName(reportName, source.contestName, extension: format.fileExtension);
    return saveFile(name, exportCsv(source, format));
  }
}
