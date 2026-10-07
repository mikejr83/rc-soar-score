import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Landing tables and their entries in the database.
class LandingTableRepository extends DriftRepository
    implements core.LandingTableRepository {
  LandingTableRepository(super.db, {super.stores});

  late final _tables = store<core.LandingTable>('LandingTable');
  late final _results = store<core.LandingResult>('LandingResult');

  @override
  Future<core.LandingTableWithResults?> findById(core.Id id) async {
    final table = await _tables.find(id);
    return table == null ? null : _withResults(table);
  }

  @override
  Future<List<core.LandingTableWithResults>> listVisibleTo({
    core.Id? ownerAccountId,
  }) async {
    final tables = [
      for (final table in await _tables.all(orderBy: 'name, id'))
        if (table.isSystem || table.ownerAccountId == ownerAccountId) table,
    ];
    return [for (final table in tables) await _withResults(table)];
  }

  @override
  Future<core.LandingTableWithResults> create(
    core.LandingTableWithResults table, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run(
    (context) => context.appendLandingTable(table, metadata: metadata),
  );

  @override
  Future<bool> isInUse(core.Id id) async {
    final references = [
      store<core.ContestConfigurationRevision>('ContestConfigurationRevision')
          .whereId('landing_table_id', id),
      store<core.ContestConfigurationPreset>('ContestConfigurationPreset')
          .whereId('landing_table_id', id),
      store<core.DisciplineProfile>('DisciplineProfile')
          .whereId('default_landing_table_id', id),
    ];
    for (final found in references) {
      if ((await found).isNotEmpty) return true;
    }
    return false;
  }

  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      unitOfWork.run((context) async {
        final table = await _tables.find(id);
        if (table == null) return false;
        await context.removeLandingTable(table, metadata: metadata);
        return true;
      });

  @override
  Future<bool> installSystemTable(core.LandingTableWithResults table) {
    if (!table.table.isSystem) {
      throw ArgumentError.value(
        table.table.id.value,
        'table',
        'must be a system table with no owner',
      );
    }
    return db.transaction(() async {
      if (await _tables.findJson(table.table.id) != null) return false;
      await _tables.upsertJson(_tables.encode(table.table));
      for (final result in table.results) {
        await _results.upsertJson(_results.encode(result));
      }
      return true;
    });
  }

  Future<core.LandingTableWithResults> _withResults(
    core.LandingTable table,
  ) async => core.LandingTableWithResults(
    table: table,
    results: await _results.whereId('landing_table_id', table.id),
  );
}
