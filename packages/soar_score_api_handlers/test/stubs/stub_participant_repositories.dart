import 'package:soar_score_core/soar_score_core.dart';

/// In-memory [ParticipantProfileRepository] for handler tests; a stale save
/// throws [StaleRevisionError] like the real one.
class StubParticipantProfileRepository implements ParticipantProfileRepository {
  final Map<Id, ParticipantProfile> profiles = {};

  /// The metadata of every save, oldest first.
  final List<MutationMetadata> savedWith = [];

  @override
  Future<ParticipantProfile?> findById(Id id) async => profiles[id];

  @override
  Future<List<ParticipantProfile>> listForOwner(Id accountId) async => [
    for (final profile in profiles.values)
      if (profile.ownerAccountId == accountId) profile,
  ];

  @override
  Future<ParticipantProfile> save(
    ParticipantProfile profile, {
    required MutationMetadata metadata,
  }) async {
    final current = profiles[profile.id];
    if (current != null && current.revision != profile.revision) {
      throw StaleRevisionError(
        entityType: 'ParticipantProfile',
        entityId: profile.id,
        expectedRevision: profile.revision,
        storedRevision: current.revision,
      );
    }
    savedWith.add(metadata);
    final stored = ParticipantProfile.fromJson({
      ...profile.toJson(),
      'revision': current == null ? 0 : current.revision + 1,
    });
    profiles[profile.id] = stored;
    return stored;
  }

  @override
  Future<bool> delete(Id id, {required MutationMetadata metadata}) async =>
      profiles.remove(id) != null;
}

/// In-memory [ContestParticipationRepository] for handler tests.
class StubContestParticipationRepository
    implements ContestParticipationRepository {
  final Map<Id, ContestParticipation> participations = {};

  @override
  Future<ContestParticipation?> findById(Id id) async => participations[id];

  @override
  Future<List<ContestParticipation>> listForContest(Id contestId) async => [
    for (final p in participations.values)
      if (p.contestId == contestId) p,
  ];

  @override
  Future<List<ContestParticipation>> listForProfile(
    Id participantProfileId,
  ) async => [
    for (final p in participations.values)
      if (p.participantProfileId == participantProfileId) p,
  ];

  @override
  Future<ContestParticipation> save(
    ContestParticipation participation, {
    required MutationMetadata metadata,
  }) async {
    final current = participations[participation.id];
    if (current != null && current.revision != participation.revision) {
      throw StaleRevisionError(
        entityType: 'ContestParticipation',
        entityId: participation.id,
        expectedRevision: participation.revision,
        storedRevision: current.revision,
      );
    }
    final stored = ContestParticipation.fromJson({
      ...participation.toJson(),
      'revision': current == null ? 0 : current.revision + 1,
    });
    participations[participation.id] = stored;
    return stored;
  }

  @override
  Future<bool> delete(Id id, {required MutationMetadata metadata}) async =>
      participations.remove(id) != null;
}

/// A [RoleRepository] holding the system roles plus any [roles] a test adds.
class StubRoleRepository implements RoleRepository {
  final List<Role> roles = SystemRoles.all;

  @override
  Future<List<Role>> listVisibleTo({Id? ownerAccountId}) async => [
    for (final role in roles)
      if (role.ownerAccountId == null || role.ownerAccountId == ownerAccountId)
        role,
  ];

  @override
  Future<bool> installSystemRole(Role role) =>
      throw UnimplementedError('not used by handlers');
}
