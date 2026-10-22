import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import '../sync/drift_unit_of_work.dart';
import '../sync/entity_store.dart';
import '../sync/entity_stores.dart';
import 'audit_event_repository.dart';

/// Backend-agnostic contest repository backed by [SoarScoreDatabase].
///
/// Reads go straight to the store. Writes go through the unit of work, so each
/// one bumps the revision and records its mutation. Works the same on SQLite
/// and PostgreSQL: the executor is chosen when the database is built.
class ContestRepository implements core.ContestRepository {
  ContestRepository(SoarScoreDatabase db)
    : this._(db, EntityStores.forDatabase(db));

  ContestRepository._(this._db, EntityStores stores)
    : _store = stores.of('Contest') as EntityStore<core.Contest>,
      _unitOfWork = DriftUnitOfWork(_db, stores),
      _audits = AuditEventRepository(_db, stores: stores);

  final SoarScoreDatabase _db;
  final EntityStore<core.Contest> _store;
  final core.UnitOfWork _unitOfWork;
  final AuditEventRepository _audits;

  @override
  Future<core.Contest?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.Contest>> getAll() => _store.all(orderBy: 'created_at, id');

  @override
  Future<core.Contest> save(
    core.Contest contest, {
    required core.MutationMetadata metadata,
    core.AuditEvent? audit,
  }) => _unitOfWork.run((context) async {
    final saved = await context.save(contest, metadata: metadata);
    if (audit != null) await _audits.append(audit);
    return saved;
  });

  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      _unitOfWork.run((context) async {
        final contest = await _store.find(id);
        if (contest == null) return false;
        await context.delete(contest, metadata: metadata);
        return true;
      });

  @override
  Future<void> close() => _db.close();
}
