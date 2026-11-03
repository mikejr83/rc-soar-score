import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';
import 'latest_timestamps.dart';

/// Invitations in the database; backend only, so written without a
/// mutation.
class InvitationRepository extends DriftRepository
    implements core.InvitationRepository {
  InvitationRepository(super.db, {super.stores});

  late final _store = backendStore<core.Invitation>('Invitation');

  @override
  Future<core.Invitation?> findById(core.Id id) async => _store.find(id);

  @override
  Future<core.Invitation?> findByClientMutationId({
    required core.Id contestId,
    required String clientMutationId,
  }) async {
    final found = await _store.whereText(
      'client_mutation_id',
      clientMutationId,
      orderBy: 'id',
    );
    return found.where((i) => i.contestId == contestId).firstOrNull;
  }

  @override
  Future<core.Invitation?> findByProtectedCredential(String credential) async {
    final found = await _store.whereText(
      'protected_credential',
      credential,
      orderBy: 'id',
    );
    return found.firstOrNull;
  }

  @override
  Future<List<core.Invitation>> listForParticipation(
    core.Id contestParticipationId,
  ) async => _store.whereId(
    'contest_participation_id',
    contestParticipationId,
    orderBy: 'invitation_revision',
  );

  @override
  Future<core.Invitation?> findActiveForParticipation(
    core.Id contestParticipationId,
  ) async {
    final all = await listForParticipation(contestParticipationId);
    return all.where((i) => i.isActive).firstOrNull;
  }

  @override
  Future<List<core.Invitation>> listForContest(core.Id contestId) async =>
      _store.whereId('contest_id', contestId, orderBy: 'id');

  @override
  Future<Map<core.Id, DateTime>> latestIssuedAtForContests(
    Iterable<core.Id> contestIds,
  ) => latestTimestampByContest(
    db,
    table: 'invitations',
    column: 'issued_at',
    contestIds: contestIds,
  );

  @override
  Future<core.Invitation> save(core.Invitation invitation) async {
    await _store.upsertJson(_store.encode(invitation));
    return invitation;
  }
}
