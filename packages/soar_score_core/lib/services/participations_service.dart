import '../enums/lifecycle_state.dart';
import '../enums/role_type.dart';
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
  /// [roleId] null keeps the role. A pilot with assignments cannot become a
  /// non-flier ([ContestStateError]). Throws a [StaleRevisionError] when
  /// [baseRevision] is not the stored revision, and an [ArgumentError] when
  /// the result breaks a participation rule (a non-pilot with a
  /// classification or a retirement round).
  Future<ContestParticipation> update(
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

    if (role != null &&
        stored.roleType == RoleType.pilot &&
        role.type != RoleType.pilot) {
      final assignments = await repository.matrixAssignmentRepository
          .listForParticipation(id);
      if (assignments.isNotEmpty) {
        throw ContestStateError(
          'has_assignments',
          'a pilot with flight assignments cannot become a non-flier',
        );
      }
    }
    if (stored.revision != baseRevision) {
      throw StaleRevisionError(
        entityType: stored.entityType,
        entityId: id,
        expectedRevision: baseRevision,
        storedRevision: stored.revision,
      );
    }
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
    return repository.contestParticipationRepository.save(
      updated,
      metadata: metadata,
    );
  }

  /// Removes participation [id] from contest [contestId], with its team
  /// memberships.
  ///
  /// One with flight assignments is refused with a [ContestStateError]: the
  /// pilot retires instead.
  Future<void> remove(
    Id contestId,
    Id id, {
    required MutationMetadata metadata,
  }) async {
    await _require(contestId, id);
    final assignments = await repository.matrixAssignmentRepository
        .listForParticipation(id);
    if (assignments.isNotEmpty) {
      throw ContestStateError(
        'has_assignments',
        'a participant with flight assignments cannot be removed; '
            'retire the pilot instead',
      );
    }
    await repository.contestParticipationRepository.delete(
      id,
      metadata: metadata,
    );
  }

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
