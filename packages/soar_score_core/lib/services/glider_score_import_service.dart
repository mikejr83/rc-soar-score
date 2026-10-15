import '../errors/glider_score_import_error.dart';
import '../import/glider_score_import_runner.dart';
import '../models/id.dart';
import '../models/imports/glider_score_import_result.dart';

/// The rules of a GliderScore import, on top of a [GliderScoreImportRunner].
///
/// The runner only knows how to open a file and stream its tables; this
/// service decides which tables are wanted, guards the row budget, and
/// assembles the [GliderScoreImportResult] the wizard reviews. All failures
/// are [GliderScoreImportError]s the API maps to an HTTP status.
class GliderScoreImportService {
  GliderScoreImportService({this.rowCap = 200000});

  /// How many rows at most one table carries into the result.
  final int rowCap;

  /// Imports [dbPath] through [runner], returning only the tables in
  /// [tables] (all of them, in database order, when [tables] is null).
  ///
  /// [dbPath] is a `.mdb` file readable to the server; [tables] is the set
  /// of names the wizard picked.
  Future<GliderScoreImportResult> importFile(
    GliderScoreImportRunner runner, {
    required String dbPath,
    Set<String>? tables,
  }) async {
    final file = dbPath.trim();
    if (!_isMdb(file)) {
      throw ImportUnsupportedFileError(
        'the file must be a GliderScore .mdb database',
      );
    }

    final availability = await runner.availability();
    if (!availability.available) {
      throw ImportUnavailableError(
        availability.reason ?? 'GliderScore import is unavailable on this machine',
      );
    }

    final allTables = await runner.listTables(file);
    final List<String> wanted = tables == null
        ? allTables
        : _validateRequested(tables, allTables);

    final resultTables = <GliderScoreTable>[];
    for (final table in wanted) {
      final stream = await runner.exportTable(file, table);
      resultTables.add(await _capture(stream));
    }

    return GliderScoreImportResult(
      id: Id.create(),
      sourceDbFile: file.split(RegExp('[\\\\/]')).last,
      tables: resultTables,
    );
  }

  bool _isMdb(String file) =>
      file.toLowerCase().endsWith('.mdb');

  /// The requested names, in the order asked, after checking each exists.
  List<String> _validateRequested(Set<String> tables, List<String> all) {
    final known = all.toSet();
    final missing = tables.toSet().difference(known);
    if (missing.isNotEmpty) {
      throw ImportTableMissingError(
        'these tables are not in the database: ${missing.join(', ')}',
      );
    }
    return tables.toList();
  }

  /// Drains a table stream, counting all rows but keeping only the first
  /// [rowCap] of them.
  Future<GliderScoreTable> _capture(ImportTableStream stream) async {
    final kept = <Map<String, Object?>>[];
    var count = 0;
    await for (final row in stream.rows) {
      count++;
      if (count <= rowCap) {
        kept.add(row);
      }
    }
    return GliderScoreTable(
      name: stream.table,
      rows: kept,
      rowCount: count,
      rowCapExceeded: count > rowCap,
    );
  }
}
