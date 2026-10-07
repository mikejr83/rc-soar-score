import '../enums/landing_input_unit.dart';
import '../errors/contest_state_error.dart';
import '../errors/entity_not_found_error.dart';
import '../models/id.dart';
import '../models/landing/landing_result.dart';
import '../models/landing/landing_table.dart';
import '../models/landing/landing_table_with_results.dart';
import '../repositories/already_stored_error.dart';
import '../repositories/mutation_metadata.dart';
import '../repositories/repository.dart';
import 'landing_entry_input.dart';
import 'landing_table_view.dart';

/// The landing table operations of the API.
///
/// A director sees the system tables and their own. Tables never change; a
/// director's table can be removed only while nothing refers to it.
class LandingTablesService {
  LandingTablesService(
    this.repository, {
    DateTime Function()? clock,
    Id Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? Id.create;

  final Repository repository;
  final DateTime Function() _clock;
  final Id Function() _newId;

  /// The system tables and those of [ownerAccountId], by name, each marked
  /// with whether it is in use.
  Future<List<LandingTableView>> list(Id ownerAccountId) async {
    final tables = await repository.landingTableRepository.listVisibleTo(
      ownerAccountId: ownerAccountId,
    );
    return [for (final table in tables) await _view(table)];
  }

  /// Creates a table owned by [ownerAccountId] from [entries], in order.
  ///
  /// Idempotent on [id]: repeating the same request returns the stored
  /// table; the same id with different content throws an
  /// [AlreadyStoredError]. Invalid input (a blank name, no entries, a
  /// repeated key, negative points) throws an [ArgumentError].
  Future<LandingTableView> create(
    Id ownerAccountId,
    Id id, {
    required String name,
    required LandingInputUnit inputUnit,
    required List<LandingEntryInput> entries,
    required MutationMetadata metadata,
  }) async {
    final table = LandingTable(
      id: id,
      ownerAccountId: ownerAccountId,
      name: name.trim(),
      inputUnit: inputUnit,
      createdAt: _clock().toUtc(),
    );
    final content = LandingTableWithResults(
      table: table,
      results: [
        for (var i = 0; i < entries.length; i++)
          LandingResult(
            id: _newId(),
            landingTableId: id,
            entryKey: entries[i].entryKey.trim(),
            displayValue: entries[i].displayValue.trim().isEmpty
                ? entries[i].entryKey.trim()
                : entries[i].displayValue.trim(),
            pointValue: entries[i].pointValue,
            ordinalPosition: i + 1,
          ),
      ],
    );
    final stored = await repository.landingTableRepository.findById(id);
    if (stored != null) {
      if (stored.table.ownerAccountId == ownerAccountId &&
          _sameContent(stored, content)) {
        return _view(stored);
      }
      throw AlreadyStoredError(entityType: 'LandingTable', entityId: id);
    }
    return _view(
      await repository.landingTableRepository.create(
        content,
        metadata: metadata,
      ),
    );
  }

  /// Removes the table [id] of [ownerAccountId].
  ///
  /// A system table, or one that is in use, is refused with a
  /// [ContestStateError]; another director's table is not found.
  Future<void> delete(
    Id ownerAccountId,
    Id id, {
    required MutationMetadata metadata,
  }) async {
    final stored = await repository.landingTableRepository.findById(id);
    if (stored == null ||
        (!stored.table.isSystem &&
            stored.table.ownerAccountId != ownerAccountId)) {
      throw EntityNotFoundError(entityType: 'LandingTable', entityId: id);
    }
    if (stored.table.isSystem) {
      throw ContestStateError(
        'system_table',
        'a system landing table cannot be removed',
      );
    }
    if (await repository.landingTableRepository.isInUse(id)) {
      throw ContestStateError(
        'in_use',
        'the landing table is used by a contest; create a copy to change it',
      );
    }
    await repository.landingTableRepository.delete(id, metadata: metadata);
  }

  Future<LandingTableView> _view(LandingTableWithResults table) async =>
      LandingTableView(
        content: table,
        inUse: await repository.landingTableRepository.isInUse(table.table.id),
      );

  static bool _sameContent(
    LandingTableWithResults a,
    LandingTableWithResults b,
  ) =>
      a.table.name == b.table.name &&
      a.table.inputUnit == b.table.inputUnit &&
      a.results.length == b.results.length &&
      [
        for (var i = 0; i < a.results.length; i++)
          a.results[i].entryKey == b.results[i].entryKey &&
              a.results[i].displayValue == b.results[i].displayValue &&
              a.results[i].pointValue == b.results[i].pointValue,
      ].every((same) => same);
}
