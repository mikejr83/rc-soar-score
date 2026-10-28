import '../enums/lifecycle_state.dart';
import '../enums/role_type.dart';
import '../enums/score_placeholder_state.dart';
import '../errors/contest_state_error.dart';
import '../errors/entity_not_found_error.dart';
import '../models/contest/contest.dart';
import '../models/id.dart';
import '../models/participants/contest_participation.dart';
import '../models/participants/role.dart';
import '../models/participants/system_roles.dart';
import '../models/shared/scoring_uuid.dart';
import '../repositories/already_stored_error.dart';
import '../repositories/mutation_metadata.dart';
import '../repositories/repository.dart';
import '../repositories/stale_revision_error.dart';

/// The contest participation operations of the API: who takes part in a
/// contest, in which role.
///
/// A participation links one of the director's participant profiles to a
/// contest. It holds no name or other identity detail, which are read from
/// the profile.
class ParticipationsService {
  ParticipationsService(this.repository);

  final Repository repository;

  /// The participations of contest [contestId], in the order they were added.
  ///
  /// Throws an [EntityNotFoundError] when the contest does not exist.
  Future<List<ContestParticipation>> list(Id contestId) async {
    await _requireContest(contestId);
    return repository.contestParticipationRepository.listForContest(contestId);
  }

  /// Adds the profile [participantProfileId] of [ownerAccountId] to contest
  /// [contestId] as role [roleId] (the system Pilot role when null).
  ///
  /// Idempotent on [id]: repeating the same request returns the stored
  /// participation. A different participation of the same profile, or the
  /// same id with different content, throws an [AlreadyStoredError]. A
  /// Completed contest takes no new participants ([ContestStateError]). The
  /// role must be visible to the director and not archived, and its name and
  /// type are copied onto the participation. The participant number stays
  /// empty: it is allocated at the first draw.
  Future<ContestParticipation> add(
    Id contestId,
    Id ownerAccountId, {
    required Id id,
    required Id participantProfileId,
    Id? roleId,
    String? classification,
    required MutationMetadata metadata,
  }) async {
    final contest = await _requireContest(contestId);
    await _requireProfile(ownerAccountId, participantProfileId);
    final role = await _requireRole(
      ownerAccountId,
      roleId ?? SystemRoles.pilotId,
    );

    final participations = repository.contestParticipationRepository;
    final stored = await participations.findById(id);
    if (stored != null) {
      if (stored.contestId == contestId &&
          stored.participantProfileId == participantProfileId &&
          stored.roleId == role.id &&
          stored.classification == _blankToNull(classification)) {
        return stored;
      }
      throw AlreadyStoredError(
        entityType: 'ContestParticipation',
        entityId: id,
      );
    }
    if (contest.lifecycleState == LifecycleState.completed) {
      throw ContestStateError(
        'contest_completed',
        'a Completed contest takes no new participants',
      );
    }
    final existing = (await participations.listForContest(contestId))
        .where((p) => p.participantProfileId == participantProfileId);
    if (existing.isNotEmpty) {
      throw AlreadyStoredError(
        entityType: 'ContestParticipation',
        entityId: existing.first.id,
      );
    }
    return participations.save(
      ContestParticipation(
        id: id,
        contestId: contestId,
        participantProfileId: participantProfileId,
        classification: _blankToNull(classification),
        roleId: role.id,
        roleName: role.displayName,
        roleType: role.type,
        scoringUuid: ScoringUuid.create(),
      ),
      metadata: metadata,
    );
  }

  /// Changes the role, classification and retirement of participation
  /// [id] in contest [contestId].
  ///
  /// [roleId] null keeps the role. A pilot who becomes a non-flier gives up
  /// their matrix rows: a pilot with no scores has them removed (the draw
  /// then needs redoing, and the answer says how many went), and one with a
  /// score is refused with a [ContestStateError] (`has_scores`; they retire
  /// instead). Throws a [StaleRevisionError] when [baseRevision] is not the
  /// stored revision, and an [ArgumentError] when the result breaks a
  /// participation rule (a non-pilot with a classification or a retirement
  /// round).
  Future<({ContestParticipation participation, int matrixRowsRemoved})> update(
    Id contestId,
    Id ownerAccountId,
    Id id, {
    Id? roleId,
    String? classification,
    int? retiredAtRound,
    required int baseRevision,
    required MutationMetadata metadata,
  }) async {
    final stored = await _require(contestId, id);
    final role = roleId == null || roleId == stored.roleId
        ? null
        : await _requireRole(ownerAccountId, roleId);

    final leavesFlying =
        role != null &&
        stored.roleType == RoleType.pilot &&
        role.type != RoleType.pilot;
    if (leavesFlying) {
      await _requireNoScores(id, 'cannot become a non-flier');
    }
    if (stored.revision != baseRevision) {
      throw StaleRevisionError(
        entityType: stored.entityType,
        entityId: id,
        expectedRevision: baseRevision,
        storedRevision: stored.revision,
      );
    }
    final removed = leavesFlying ? await _matrixRowCount(id) : 0;
    final updated = ContestParticipation(
      id: stored.id,
      contestId: stored.contestId,
      participantProfileId: stored.participantProfileId,
      classification: _blankToNull(classification),
      roleId: role?.id ?? stored.roleId,
      roleName: role?.displayName ?? stored.roleName,
      roleType: role?.type ?? stored.roleType,
      participantNumber: stored.participantNumber,
      scoringUuid: stored.scoringUuid,
      retiredAtRound: retiredAtRound,
      revision: stored.revision,
    );
    // The matrix rows go in the same transaction as the role, so a change
    // that loses to another edit removes nothing.
    final saved = await repository.contestParticipationRepository.save(
      updated,
      metadata: metadata,
      removeMatrixRows: leavesFlying,
    );
    return (participation: saved, matrixRowsRemoved: removed);
  }

  /// Removes participation [id] from contest [contestId], with its team
  /// memberships.
  ///
  /// A pilot with matrix rows but no scores leaves with them: the rows and
  /// their empty score slots are removed, the matrix revision stays, and the
  /// number removed is returned so the caller can say the draw needs redoing.
  /// One with a score is refused with a [ContestStateError] (`has_scores`):
  /// the pilot retires instead.
  Future<int> remove(
    Id contestId,
    Id id, {
    required MutationMetadata metadata,
  }) async {
    await _require(contestId, id);
    await _requireNoScores(id, 'cannot be removed');
    final removed = await _matrixRowCount(id);
    await repository.contestParticipationRepository.delete(
      id,
      metadata: metadata,
    );
    return removed;
  }

  /// Refuses with a [ContestStateError] when the pilot of [id] has a score,
  /// or a re-flight, which only exists beside scores.
  Future<void> _requireNoScores(Id id, String what) async {
    final placeholders = await repository.scorePlaceholderRepository
        .listForParticipation(id);
    final scored = placeholders.any(
      (p) => p.state != ScorePlaceholderState.notEntered || p.scoreRevision > 0,
    );
    if (scored) {
      throw ContestStateError(
        'has_scores',
        'a participant with scores $what; retire the pilot instead',
      );
    }
    final reFlights = await repository.reFlightParticipantRepository
        .listForParticipation(id);
    if (reFlights.isNotEmpty) {
      throw ContestStateError(
        'has_scores',
        'a participant with re-flights $what; retire the pilot instead',
      );
    }
  }

  Future<int> _matrixRowCount(Id id) async =>
      (await repository.matrixAssignmentRepository.listForParticipation(id))
          .length;

  Future<Contest> _requireContest(Id contestId) async {
    final contest = await repository.contestRepository.findById(contestId);
    if (contest == null) {
      throw EntityNotFoundError(entityType: 'Contest', entityId: contestId);
    }
    return contest;
  }

  Future<void> _requireProfile(Id ownerAccountId, Id profileId) async {
    final profile = await repository.participantProfileRepository.findById(
      profileId,
    );
    if (profile == null || profile.ownerAccountId != ownerAccountId) {
      throw EntityNotFoundError(
        entityType: 'ParticipantProfile',
        entityId: profileId,
      );
    }
  }

  Future<Role> _requireRole(Id ownerAccountId, Id roleId) async {
    final roles = await repository.roleRepository.listVisibleTo(
      ownerAccountId: ownerAccountId,
    );
    final role = roles.where((r) => r.id == roleId).firstOrNull;
    if (role == null) {
      throw EntityNotFoundError(entityType: 'Role', entityId: roleId);
    }
    if (role.isArchived) {
      throw ArgumentError.value(
        roleId.value,
        'roleId',
        'is an archived role and cannot be assigned',
      );
    }
    return role;
  }

  Future<ContestParticipation> _require(Id contestId, Id id) async {
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

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
