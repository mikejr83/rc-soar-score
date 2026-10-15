/// A GliderScore `.mdb` file, read through an external helper.
///
/// The core never touches the file system or spawns processes; it speaks
/// to a [GliderScoreImportRunner], whose implementation lives in
/// `soar_score_data`. See the architecture in
/// `plan/research/gliderscore-mdb-import/backend-plan.md`.
abstract interface class GliderScoreImportRunner {
  /// Whether GliderScore import is possible on this machine: the helper
  /// binaries are present next to the running executable.
  Future<ImportAvailability> availability();

  /// The table names of the database at [dbPath], in database order.
  Future<List<String>> listTables(String dbPath);

  /// The rows of [table] in the database at [dbPath], one JSON object per
  /// line, streamed in file order.
  Future<ImportTableStream> exportTable(String dbPath, String table);
}

/// The answer of [GliderScoreImportRunner.availability].
class ImportAvailability {
  const ImportAvailability({
    required this.available,
    this.executablePath,
    this.reason,
  });

  final bool available;

  /// Where the helpers live, to show the user what runs their import.
  final String? executablePath;

  /// Why import is unavailable, when [available] is false.
  final String? reason;
}

/// A table being exported: its name and a stream of its row objects.
class ImportTableStream {
  const ImportTableStream({required this.table, required this.rows});

  final String table;

  /// The rows, each one object decoded from a single JSON line.
  final Stream<Map<String, Object?>> rows;
}
