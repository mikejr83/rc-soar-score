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

  /// Installs [table] unless its row exists. Writes the table and its entries
  /// in one transaction, unless the caller is already in one ([atomic] false).
  @override
  Future<bool> installSystemTable(
    core.LandingTableWithResults table, {
    bool atomic = true,
  }) {
    if (!table.table.isSystem) {
      throw ArgumentError.value(
        table.table.id.value,
        'table',
        'must be a system table with no owner',
      );
    }
    Future<bool> install() async {
      final inserted = await _tables.insertMissingJson([
        _tables.encode(table.table),
      ]);
      if (inserted == 0) return false;
      await _results.insertMissingJson([
        for (final result in table.results) _results.encode(result),
      ]);
      return true;
    }

    return atomic ? db.transaction(install) : install();
  }

  Future<core.LandingTableWithResults> _withResults(
    core.LandingTable table,
  ) async => core.LandingTableWithResults(
    table: table,
    results: await _results.whereId('landing_table_id', table.id),
  );
}
