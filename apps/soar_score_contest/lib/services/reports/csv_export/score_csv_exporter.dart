import 'csv_builder.dart';
import 'csv_file_name.dart';
import 'save_csv_platform.dart' as platform;
import 'score_csv_format.dart';
import 'score_export_error.dart';
import 'score_export_source.dart';

/// Saves a file and answers the name written, or `null` when the director
/// cancelled. The web build downloads a blob; the native build uses the save
/// dialog. [extension] is the format's file extension, so a non-CSV target is
/// saved with its own extension. A test swaps in a recorder with no real IO.
typedef SaveCsvFile = Future<String?> Function(
  String fileName,
  String csv, {
  String extension,
});

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

  /// The CSV for [source] in [format]: a header, then the rows, with a UTF-8
  /// BOM when the format writes one.
  String exportCsv(ScoreExportSource source, ScoreCsvFormat format) {
    final csv = builder.build(format.build(source));
    return format.writeBom ? '\uFEFF$csv' : csv;
  }

  /// Exports and saves [source] in [format], naming the file from the report
  /// and contest names and the format's extension. Answers the file name, or
  /// `null` when the director cancelled. A save that fails throws a
  /// [ScoreExportError]; only a director cancel answers `null`.
  Future<String?> saveCsv(
    ScoreExportSource source,
    ScoreCsvFormat format, {
    required String reportName,
  }) async {
    final name = csvFileName(
      reportName,
      source.contestName,
      extension: format.fileExtension,
    );
    // The CSV is built outside the try, so a format bug reports its own error
    // and the save only guards the IO.
    final csv = exportCsv(source, format);
    try {
      return await saveFile(name, csv, extension: format.fileExtension);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        ScoreExportError('Saving "$name" failed: $error'),
        stackTrace,
      );
    }
  }
}
