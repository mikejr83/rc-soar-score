import 'package:drift/drift.dart' show DriftSqlType, Variable;
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

/// A native installation with system data and a Local account.
class Site {
  Site._(this.inst, this.localId);

  static Future<Site> open({bool demo = false, bool system = true}) async {
    final inst = await Installation.open(Backend.sqlite);
    if (system) await SystemDataSeeder(inst.db).seed();
    final localId = await LocalAccountRepository(inst.db).ensure();
    if (demo) {
      await DemoDataSeeder(Repository(inst.db), localAccountId: localId).seed();
    }
    return Site._(inst, localId);
  }

  final Installation inst;
  final core.Id localId;

  SoarScoreDatabase get db => inst.db;

  ContestExporter get exporter =>
      ContestExporter(db, clock: () => DateTime.utc(2026, 10, 22, 12));

  ContestImporter get importer =>
      ContestImporter(db, clock: () => DateTime.utc(2026, 10, 22, 13));

  ImportTarget get target => ImportTarget(localAccountId: localId);

  Future<core.Contest> contestNamed(String name) async => (await Repository(
    db,
  ).contestRepository.getAll()).firstWhere((c) => c.name == name);

  /// Exports [name] and decodes the file again, as a recipient would.
  Future<ExchangeFile> exportNamed(
    String name, {
    bool redact = false,
    ExportSource source = const ExportSource(label: 'Director Dana'),
  }) async {
    final contest = await contestNamed(name);
    final file = await exporter.export(
      contest.id,
      redact: redact,
      source: source,
    );
    return ExchangeFile.decode(file.encode());
  }

  Future<void> close() => inst.close();
}

/// The count of rows in [table] whose [column] equals [value].
Future<int> countWhere(
  SoarScoreDatabase db,
  String table,
  String column,
  String value,
) async =>
    (await db
            .customSelect(
              'SELECT COUNT(*) AS n FROM $table WHERE $column = ?',
              variables: [Variable.withString(value)],
            )
            .getSingle())
        .read<int>('n');

/// Every `table.column` of [db] whose text contains [value], with the count.
Future<Map<String, int>> occurrences(SoarScoreDatabase db, String value) async {
  final found = <String, int>{};
  for (final table in db.profileTables) {
    final name = table.actualTableName;
    if (name == 'local_account') continue;
    for (final column in table.$columns) {
      if (column.type != DriftSqlType.string) continue;
      final n =
          (await db
                  .customSelect(
                    'SELECT COUNT(*) AS n FROM $name WHERE ${column.name} LIKE ?',
                    variables: [Variable.withString('%$value%')],
                  )
                  .getSingle())
              .read<int>('n');
      if (n > 0) found['$name.${column.name}'] = n;
    }
  }
  return found;
}

/// The rows of [spec]'s table that belong to the contest (or the given ids).
Future<List<Map<String, Object?>>> rowsOf(
  SoarScoreDatabase db,
  ExchangeTable spec,
  String key,
) async {
  final store = EntityStores.forDatabase(db).of(spec.entityType);
  final rows = spec.contestColumn == 'id'
      ? [?await store.findJson(core.Id.parse(key))]
      : await store.whereIdJson(spec.contestColumn, core.Id.parse(key));
  return rows..sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
}
