import '../enums/lifecycle_state.dart';
import '../enums/role_type.dart';
import '../errors/contest_state_error.dart';
import '../errors/entity_not_found_error.dart';
import '../models/contest/contest.dart';
import '../models/id.dart';
import '../models/participants/contest_participation.dart';
import '../models/teams/team.dart';
import '../models/teams/team_membership.dart';
import '../repositories/already_stored_error.dart';
import '../repositories/mutation_metadata.dart';
import '../repositories/repository.dart';
import '../repositories/stale_revision_error.dart';

/// The team operations of the API: a contest's teams and who is on them.
///
/// A team is a named grouping inside one contest. Membership joins a
/// participation to a team, and a participation is on at most one team.
/// Pilot membership is fixed once a matrix has been drawn, because the draw
/// protects teammates from each other; non-fliers can join and leave freely.
class TeamsService {
  TeamsService(this.repository);

  final Repository repository;

  /// The teams of contest [contestId], by name.
  ///
  /// Throws an [EntityNotFoundError] when the contest does not exist.
  Future<List<Team>> listTeams(Id contestId) async {
    await _requireContest(contestId);
    return repository.teamRepository.listForContest(contestId);
  }

  /// Creates team [id] named [name] in contest [contestId].
  ///
  /// Idempotent on [id]: repeating the same request returns the stored team.
  /// The same id with another name, or another team of that name in the
  /// contest, throws an [AlreadyStoredError]. A Completed contest takes no
  /// new teams ([ContestStateError]).
  Future<Team> createTeam(
    Id contestId, {
    required Id id,
    required String name,
    required MutationMetadata metadata,
  }) async {
    final contest = await _requireContest(contestId);
    final team = Team(id: id, contestId: contestId, name: name.trim());

    final stored = await repository.teamRepository.findById(id);
    if (stored != null) {
      if (stored.contestId == contestId && stored.name == team.name) {
        return stored;
      }
      throw AlreadyStoredError(entityType: 'Team', entityId: id);
    }
    _requireOpen(contest, 'teams');
    await _requireNameFree(contestId, team.name);
    return repository.teamRepository.save(team, metadata: metadata);
  }

  /// Renames team [id] of contest [contestId].
  ///
  /// Throws a [StaleRevisionError] when [baseRevision] is not the stored
  /// revision.
  Future<Team> renameTeam(
    Id contestId,
    Id id, {
    required String name,
    required int baseRevision,
    required MutationMetadata metadata,
  }) async {
    final stored = await _requireTeam(contestId, id);
    final renamed = Team(
      id: id,
      contestId: contestId,
      name: name.trim(),
      revision: baseRevision,
    );
    if (renamed.name != stored.name) {
      await _requireNameFree(contestId, renamed.name);
    }
    return repository.teamRepository.save(renamed, metadata: metadata);
  }

  /// Deletes team [id] with its memberships.
  ///
  /// A team with pilots is refused with a [ContestStateError] once a matrix
  /// has been drawn.
  Future<void> deleteTeam(
    Id contestId,
    Id id, {
    required MutationMetadata metadata,
  }) async {
    await _requireTeam(contestId, id);
    final members = await repository.teamMembershipRepository.listForTeam(id);
    for (final member in members) {
      await _requirePilotChangeAllowed(
        contestId,
        member.contestParticipationId,
      );
    }
    await repository.teamRepository.delete(id, metadata: metadata);
  }

  /// Every membership of contest [contestId].
  Future<List<TeamMembership>> listMemberships(Id contestId) async {
    await _requireContest(contestId);
    return repository.teamMembershipRepository.listForContest(contestId);
  }

  /// Puts participation [participationId] on team [teamId].
  ///
  /// Idempotent on [id]. A participation already on a team, or the same id
  /// with other content, throws an [AlreadyStoredError]: remove the old
  /// membership first. A pilot cannot join once a matrix has been drawn
  /// ([ContestStateError]).
  Future<TeamMembership> addMember(
    Id contestId, {
    required Id id,
    required Id teamId,
    required Id participationId,
    required MutationMetadata metadata,
  }) async {
    final contest = await _requireContest(contestId);
    await _requireTeam(contestId, teamId);
    final participation = await _requireParticipation(
      contestId,
      participationId,
    );

    final memberships = repository.teamMembershipRepository;
    final stored = await memberships.findById(id);
    if (stored != null) {
      if (stored.contestId == contestId &&
          stored.teamId == teamId &&
          stored.contestParticipationId == participationId) {
        return stored;
      }
      throw AlreadyStoredError(entityType: 'TeamMembership', entityId: id);
    }
    _requireOpen(contest, 'team members');
    final existing = (await memberships.listForContest(contestId))
        .where((m) => m.contestParticipationId == participationId);
    if (existing.isNotEmpty) {
      throw AlreadyStoredError(
        entityType: 'TeamMembership',
        entityId: existing.first.id,
      );
    }
    if (participation.roleType == RoleType.pilot) {
      await _requirePilotChangeAllowed(contestId, participationId);
    }
    return memberships.save(
      TeamMembership(
        id: id,
        teamId: teamId,
        contestParticipationId: participationId,
        contestId: contestId,
      ),
      metadata: metadata,
    );
  }

  /// Takes a member off its team.
  ///
  /// A pilot cannot leave once a matrix has been drawn ([ContestStateError]).
  Future<void> removeMember(
    Id contestId,
    Id id, {
    required MutationMetadata metadata,
  }) async {
    final membership = await repository.teamMembershipRepository.findById(id);
    if (membership == null || membership.contestId != contestId) {
      throw EntityNotFoundError(entityType: 'TeamMembership', entityId: id);
    }
    await _requirePilotChangeAllowed(
      contestId,
      membership.contestParticipationId,
    );
    await repository.teamMembershipRepository.delete(id, metadata: metadata);
  }

  /// Refuses a change to a pilot's team once a matrix exists.
  Future<void> _requirePilotChangeAllowed(
    Id contestId,
    Id participationId,
  ) async {
    final participation = await repository.contestParticipationRepository
        .findById(participationId);
    if (participation == null || participation.roleType != RoleType.pilot) {
      return;
    }
    final matrix = await repository.matrixRevisionRepository.latestForContest(
      contestId,
    );
    if (matrix != null) {
      throw ContestStateError(
        'matrix_exists',
        'pilot team membership is fixed once a matrix has been drawn',
      );
    }
  }

  void _requireOpen(Contest contest, String what) {
    if (contest.lifecycleState == LifecycleState.completed) {
      throw ContestStateError(
        'contest_completed',
        'a Completed contest takes no new $what',
      );
    }
  }

  Future<void> _requireNameFree(Id contestId, String name) async {
    final teams = await repository.teamRepository.listForContest(contestId);
    final clash = teams.where(
      (t) => t.name.toLowerCase() == name.toLowerCase(),
    );
    if (clash.isNotEmpty) {
      throw AlreadyStoredError(entityType: 'Team', entityId: clash.first.id);
    }
  }

  Future<Contest> _requireContest(Id contestId) async {
    final contest = await repository.contestRepository.findById(contestId);
    if (contest == null) {
      throw EntityNotFoundError(entityType: 'Contest', entityId: contestId);
    }
    return contest;
  }

  Future<Team> _requireTeam(Id contestId, Id id) async {
    final team = await repository.teamRepository.findById(id);
    if (team == null || team.contestId != contestId) {
      throw EntityNotFoundError(entityType: 'Team', entityId: id);
    }
    return team;
  }

  Future<ContestParticipation> _requireParticipation(
    Id contestId,
    Id id,
  ) async {
    final participation = await repository.contestParticipationRepository
        .findById(id);
    if (participation == null || participation.contestId != contestId) {
      throw EntityNotFoundError(
        entityType: 'ContestParticipation',
        entityId: id,
      );
    }
    return participation;
  }
}
