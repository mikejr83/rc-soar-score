import 'package:drift/drift.dart' show Variable;
import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Audit events in the database; append-only.
///
/// Written directly, not through the unit of work: an event is not itself a
/// change to synchronize, and a rejected action must still leave one.
class AuditEventRepository extends DriftRepository
    implements core.AuditEventRepository {
  AuditEventRepository(super.db, {super.stores});

  late final _store = store<core.AuditEvent>('AuditEvent');

  @override
  Future<core.AuditEvent?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.AuditEvent>> listForPublication(core.Id publicationId) =>
      _store.whereId(
        'publication_id',
        publicationId,
        orderBy: 'server_timestamp, id',
      );

  @override
  Future<Set<int>> systemPublishRevisions(
    core.Id publicationId,
    Iterable<int> revisions,
  ) async {
    final wanted = revisions.toSet().toList();
    if (wanted.isEmpty) return {};
    final events = await _store.whereSql(
      'publication_id = ? AND action = ? AND outcome = ? AND authority = ? '
      'AND resulting_revision IN (${List.filled(wanted.length, '?').join(', ')})',
      [
        Variable<String>(publicationId.value),
        Variable<String>(core.AuditAction.publicationAttempt.text),
        Variable<String>('Success'),
        Variable<String>('System'),
        for (final revision in wanted) Variable<int>(revision),
      ],
    );
    return {
      for (final event in events)
        if (event.resultingRevision != null) event.resultingRevision!,
    };
  }

  @override
  Future<List<core.AuditEvent>> listForContest(
    core.Id contestId, {
    core.AuditAction? action,
    int? limit,
  }) => _store.whereIdAndText(
    'contest_id',
    contestId,
    textColumn: action == null ? null : 'action',
    text: action?.text,
    orderBy: 'server_timestamp DESC, id DESC',
    limit: limit,
  );

  @override
  Future<core.AuditEvent> append(core.AuditEvent event) =>
      db.transaction(() async {
        if (await _store.findJson(event.id) != null) {
          throw core.AlreadyStoredError(
            entityType: _store.entityType,
            entityId: event.id,
          );
        }
        await _store.upsertJson(_store.encode(event));
        return event;
      });
}
