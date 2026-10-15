import '../id.dart';

/// The outcome of a GliderScore import.
///
/// A snapshot of the `.mdb` the user pointed at: the database it came from
/// and the tables the wizard chose, each with its raw rows. The wizard turns
/// this into a draft for review before anything is stored.
class GliderScoreImportResult {
  GliderScoreImportResult({
    required this.id,
    required this.sourceDbFile,
    required this.tables,
  });

  /// The shape of the payload a client and the wizard share over this result.
  static const schema = 'gs-import/v1';

  /// A fresh identifier for this import, for logging and retries.
  final Id id;

  /// The file name of the `.mdb`, not its path: the server never exposes the
  /// user's file system.
  final String sourceDbFile;

  /// The imported tables, in the order the wizard requested them.
  final List<GliderScoreTable> tables;

  Map<String, Object?> toJson() => <String, Object?>{
    'schema': schema,
    'id': id.value,
    'sourceDbFile': sourceDbFile,
    'tables': [for (final table in tables) table.toJson()],
  };
}

/// One table of a [GliderScoreImportResult].
class GliderScoreTable {
  const GliderScoreTable({
    required this.name,
    required this.rows,
    required this.rowCount,
    required this.rowCapExceeded,
  });

  final String name;

  /// The rows actually carried, in file order.
  final List<Map<String, Object?>> rows;

  /// How many rows the table has in the database, whether or not all of them
  /// fit under [rowCapExceeded].
  final int rowCount;

  /// True when the table is bigger than the capped row budget: [rows] holds
  /// only the first of them.
  final bool rowCapExceeded;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'rowCount': rowCount,
    'rowCapExceeded': rowCapExceeded,
    'rows': rows,
  };
}
