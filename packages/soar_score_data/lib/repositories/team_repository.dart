import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Teams in the database.
class TeamRepository extends DriftRepository implements core.TeamRepository {
  TeamRepository(super.db, {super.stores});

  late final _store = store<core.Team>('Team');
  late final _memberships = store<core.TeamMembership>('TeamMembership');

  @override
  Future<core.Team?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.Team>> listForContest(core.Id contestId) =>
      _store.whereId('contest_id', contestId, orderBy: 'name, id');

  @override
  Future<core.Team> save(
    core.Team team, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) => context.save(team, metadata: metadata));

  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      unitOfWork.run((context) async {
        final team = await _store.find(id);
        if (team == null) return false;
        for (final membership in await _memberships.whereId('team_id', id)) {
          await context.delete(
            membership,
            metadata: metadata.forPart(membership.id.value),
          );
        }
        await context.delete(team, metadata: metadata);
        return true;
      });
}
