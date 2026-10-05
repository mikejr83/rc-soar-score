import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Team memberships in the database.
class TeamMembershipRepository extends DriftRepository
    implements core.TeamMembershipRepository {
  TeamMembershipRepository(super.db, {super.stores});

  late final _store = store<core.TeamMembership>('TeamMembership');

  @override
  Future<core.TeamMembership?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.TeamMembership>> listForTeam(core.Id teamId) =>
      _store.whereId('team_id', teamId, orderBy: 'id');

  @override
  Future<List<core.TeamMembership>> listForContest(core.Id contestId) =>
      _store.whereId('contest_id', contestId, orderBy: 'id');

  @override
  Future<core.TeamMembership> save(
    core.TeamMembership membership, {
    required core.MutationMetadata metadata,
  }) =>
      unitOfWork.run((context) => context.save(membership, metadata: metadata));

  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      unitOfWork.run((context) async {
        final membership = await _store.find(id);
        if (membership == null) return false;
        await context.delete(membership, metadata: metadata);
        return true;
      });
}
