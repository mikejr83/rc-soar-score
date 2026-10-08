import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Participant account links in the database; backend only, so written
/// without a mutation.
class ParticipantAccountLinkRepository extends DriftRepository
    implements core.ParticipantAccountLinkRepository {
  ParticipantAccountLinkRepository(super.db, {super.stores});

  late final _store = backendStore<core.ParticipantAccountLink>(
    'ParticipantAccountLink',
  );

  @override
  Future<core.ParticipantAccountLink?> findById(core.Id id) async =>
      _store.find(id);

  @override
  Future<core.ParticipantAccountLink?> find({
    required core.Id participantProfileId,
    required core.Id accountId,
  }) async {
    final links = await listForProfile(participantProfileId);
    return links.where((l) => l.accountId == accountId).firstOrNull;
  }

  @override
  Future<core.ParticipantAccountLink?> findConfirmedForProfile(
    core.Id participantProfileId,
  ) async {
    final links = await listForProfile(participantProfileId);
    return links
        .where((l) => l.status == core.ParticipantLinkStatus.confirmed)
        .firstOrNull;
  }

  @override
  Future<List<core.ParticipantAccountLink>> listForProfile(
    core.Id participantProfileId,
  ) async => _store.whereId(
    'participant_profile_id',
    participantProfileId,
    orderBy: 'id',
  );

  @override
  Future<List<core.ParticipantAccountLink>> listForAccount(
    core.Id accountId,
  ) async => _store.whereId('account_id', accountId, orderBy: 'id');

  @override
  Future<core.ParticipantAccountLink> save(core.ParticipantAccountLink link) =>
      db.transaction(() async {
        final stored = await _store.findJson(link.id);
        final storedRevision = stored?['revision'] as int?;
        if (storedRevision != null && storedRevision != link.revision) {
          throw core.StaleRevisionError(
            entityType: _store.entityType,
            entityId: link.id,
            expectedRevision: link.revision,
            storedRevision: storedRevision,
          );
        }
        final json = _store.encode(link);
        json['revision'] = storedRevision == null
            ? link.revision
            : storedRevision + 1;
        final saved = _store.decode(json);
        await _store.upsertJson(_store.encode(saved));
        return saved;
      });
}
