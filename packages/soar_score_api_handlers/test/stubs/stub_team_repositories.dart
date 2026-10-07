import 'package:soar_score_core/soar_score_core.dart';

/// In-memory [TeamRepository] for handler tests.
class StubTeamRepository implements TeamRepository {
  final Map<Id, Team> teams = {};

  @override
  Future<Team?> findById(Id id) async => teams[id];

  @override
  Future<List<Team>> listForContest(Id contestId) async => [
    for (final team in teams.values)
      if (team.contestId == contestId) team,
  ]..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<Team> save(Team team, {required MutationMetadata metadata}) async {
    final current = teams[team.id];
    if (current != null && current.revision != team.revision) {
      throw StaleRevisionError(
        entityType: 'Team',
        entityId: team.id,
        expectedRevision: team.revision,
        storedRevision: current.revision,
      );
    }
    return teams[team.id] = Team.fromJson({
      ...team.toJson(),
      'revision': current == null ? 0 : current.revision + 1,
    });
  }

  @override
  Future<bool> delete(Id id, {required MutationMetadata metadata}) async =>
      teams.remove(id) != null;
}

/// In-memory [TeamMembershipRepository] for handler tests.
class StubTeamMembershipRepository implements TeamMembershipRepository {
  final Map<Id, TeamMembership> memberships = {};

  @override
  Future<TeamMembership?> findById(Id id) async => memberships[id];

  @override
  Future<List<TeamMembership>> listForTeam(Id teamId) async => [
    for (final m in memberships.values)
      if (m.teamId == teamId) m,
  ];

  @override
  Future<List<TeamMembership>> listForContest(Id contestId) async => [
    for (final m in memberships.values)
      if (m.contestId == contestId) m,
  ];

  @override
  Future<TeamMembership> save(
    TeamMembership membership, {
    required MutationMetadata metadata,
  }) async => memberships[membership.id] = membership;

  @override
  Future<bool> delete(Id id, {required MutationMetadata metadata}) async =>
      memberships.remove(id) != null;
}
