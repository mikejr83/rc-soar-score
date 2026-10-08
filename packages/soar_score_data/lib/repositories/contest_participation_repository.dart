import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Contest participations in the database.
class ContestParticipationRepository extends DriftRepository
    implements core.ContestParticipationRepository {
  ContestParticipationRepository(super.db, {super.stores});

  late final _store = store<core.ContestParticipation>('ContestParticipation');
  late final _memberships = store<core.TeamMembership>('TeamMembership');

  @override
  Future<core.ContestParticipation?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.ContestParticipation>> listForContest(core.Id contestId) =>
      _store.whereId('contest_id', contestId, orderBy: 'id');

  @override
  Future<List<core.ContestParticipation>> listForProfile(
    core.Id participantProfileId,
  ) => _store.whereId(
    'participant_profile_id',
    participantProfileId,
    orderBy: 'id',
  );

  @override
  Future<List<core.ContestParticipation>> listForRole(core.Id roleId) =>
      _store.whereId('role_id', roleId, orderBy: 'id');

  @override
  Future<core.ContestParticipation> save(
    core.ContestParticipation participation, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run(
    (context) => context.save(participation, metadata: metadata),
  );

  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      unitOfWork.run((context) async {
        final participation = await _store.find(id);
        if (participation == null) return false;
        for (final membership in await _memberships.whereId(
          'contest_participation_id',
          id,
        )) {
          await context.delete(
            membership,
            metadata: metadata.forPart(membership.id.value),
          );
        }
        await context.delete(participation, metadata: metadata);
        return true;
      });
}
