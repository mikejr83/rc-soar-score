import 'package:drift/drift.dart' show Variable;
import 'package:soar_score_core/soar_score_core.dart' as core;

import 'audit_event_repository.dart';
import 'drift_repository.dart';

/// Whether [error] is the refusal of a second pending request for one
/// publication (the `delist_requests_one_pending` index), as PostgreSQL
/// names the constraint and SQLite names the column. Any other unique
/// violation, such as one from the audit table, is not a request race.
bool isPendingRequestViolation(Object error) {
  final text = '$error'.toLowerCase();
  return text.contains('delist_requests_one_pending') ||
      text.contains('unique constraint failed: delist_requests.publication_id');
}

/// Delist requests in the database; backend only, so written without a
/// mutation.
class DelistRequestRepository extends DriftRepository
    implements core.DelistRequestRepository {
  DelistRequestRepository(super.db, {super.stores});

  late final _store = store<core.DelistRequest>('DelistRequest');
  late final _audits = AuditEventRepository(db, stores: stores);

  @override
  Future<core.DelistRequest?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.DelistRequest>> listForPublication(core.Id publicationId) =>
      _store.whereId('publication_id', publicationId, orderBy: 'id');

  @override
  Future<core.DelistRequest?> findLatestForPublication(
    core.Id publicationId,
  ) async {
    final latest = await _store.whereSql(
      'publication_id = ?',
      [Variable<String>(publicationId.value)],
      orderBy: 'id DESC',
      limit: 1,
    );
    return latest.firstOrNull;
  }

  @override
  Future<core.DelistRequest?> findPendingForPublication(
    core.Id publicationId,
  ) async {
    final requests = await listForPublication(publicationId);
    return requests
        .where((r) => r.state == core.DelistState.pending)
        .firstOrNull;
  }

  @override
  Future<List<core.DelistRequest>> listByState(core.DelistState state) async {
    final requests = await _store.all(orderBy: 'id');
    return [
      for (final request in requests)
        if (request.state == state) request,
    ];
  }

  @override
  Future<core.DelistRequest> save(core.DelistRequest request) async {
    await _store.upsertJson(_store.encode(request));
    return request;
  }

  @override
  Future<({core.DelistRequest request, bool created})> createPending(
    core.DelistRequest request,
    core.AuditEvent audit,
  ) async {
    final existing = await findPendingForPublication(request.publicationId);
    if (existing != null) return (request: existing, created: false);
    try {
      await db.transaction(() async {
        await _store.upsertJson(_store.encode(request));
        await _audits.append(audit);
      });
      return (request: request, created: true);
    } on Object catch (error) {
      // A caller racing this one stored its pending request first and the
      // one-pending index refused ours (the transaction rolled back, so no
      // audit event was kept). Answer with the winner's request.
      if (!isPendingRequestViolation(error)) rethrow;
      final winner = await findPendingForPublication(request.publicationId);
      if (winner == null) rethrow;
      return (request: winner, created: false);
    }
  }

  @override
  Future<core.DelistRequest> saveWithAudit(
    core.DelistRequest request,
    core.AuditEvent audit,
  ) => db.transaction(() async {
    await _store.upsertJson(_store.encode(request));
    await _audits.append(audit);
    return request;
  });
}
