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
  Future<List<ParticipantProfile>> saveAll(
    List<ParticipantProfile> profiles, {
    required MutationMetadata metadata,
  }) async {
    final before = Map<Id, ParticipantProfile>.of(this.profiles);
    final savedBefore = savedWith.length;
    try {
      return [
        for (final profile in profiles)
          await save(profile, metadata: metadata.forPart(profile.id.value)),
      ];
    } on Object {
      this.profiles
        ..clear()
        ..addAll(before);
      savedWith.removeRange(savedBefore, savedWith.length);
      rethrow;
    }
  }

  @override
  Future<bool> delete(Id id, {required MutationMetadata metadata}) async =>
      profiles.remove(id) != null;
}

/// In-memory [ContestParticipationRepository] for handler tests.
class StubContestParticipationRepository
    implements ContestParticipationRepository {
  final Map<Id, ContestParticipation> participations = {};

  /// Removes a participation's matrix rows; set by the repository that owns
  /// the assignments.
  Future<int> Function(Id participationId)? removeMatrixRows;

  /// Removes a participation's model links; set by the repository that owns
  /// them.
  void Function(Id participationId)? removeModelLinks;

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
  Future<List<ContestParticipation>> listForRole(Id roleId) async => [
    for (final p in participations.values)
      if (p.roleId == roleId) p,
  ];

  @override
  Future<ContestParticipation> save(
    ContestParticipation participation, {
    required MutationMetadata metadata,
  }) async => (await _store(participation, 0)).participation;

  @override
  Future<({ContestParticipation participation, int matrixRowsRemoved})>
  saveRemovingMatrixRows(
    ContestParticipation participation, {
    required MutationMetadata metadata,
  }) => _store(participation, null);

  /// Stores [participation]; with a null [removed] the matrix rows go too.
  Future<({ContestParticipation participation, int matrixRowsRemoved})> _store(
    ContestParticipation participation,
    int? removed,
  ) async {
    final current = participations[participation.id];
    if (current != null && current.revision != participation.revision) {
      throw StaleRevisionError(
        entityType: 'ContestParticipation',
        entityId: participation.id,
        expectedRevision: participation.revision,
        storedRevision: current.revision,
      );
    }
    final count =
        removed ?? await removeMatrixRows?.call(participation.id) ?? 0;
    if (removed == null) removeModelLinks?.call(participation.id);
    final stored = ContestParticipation.fromJson({
      ...participation.toJson(),
      'revision': current == null ? 0 : current.revision + 1,
    });
    participations[participation.id] = stored;
    return (participation: stored, matrixRowsRemoved: count);
  }

  @override
  Future<bool> delete(Id id, {required MutationMetadata metadata}) async =>
      (await deleteRemovingMatrixRows(id, metadata: metadata)).deleted;

  @override
  Future<({bool deleted, int matrixRowsRemoved})> deleteRemovingMatrixRows(
    Id id, {
    required MutationMetadata metadata,
  }) async {
    final count = await removeMatrixRows?.call(id) ?? 0;
    removeModelLinks?.call(id);
    return (
      deleted: participations.remove(id) != null,
      matrixRowsRemoved: count,
    );
  }
}

/// A [RoleRepository] holding the system roles plus any [roles] a test adds;
/// a stale save throws [StaleRevisionError] like the real one.
class StubRoleRepository implements RoleRepository {
  final List<Role> roles = SystemRoles.all;

  @override
  Future<List<Role>> listVisibleTo({Id? ownerAccountId}) async => [
    for (final role in roles)
      if (role.ownerAccountId == null || role.ownerAccountId == ownerAccountId)
        role,
  ];

  @override
  Future<Role?> findById(Id id) async =>
      roles.where((role) => role.id == id).firstOrNull;

  @override
  Future<Role> save(Role role, {required MutationMetadata metadata}) async {
    final index = roles.indexWhere((r) => r.id == role.id);
    if (index >= 0 && roles[index].revision != role.revision) {
      throw StaleRevisionError(
        entityType: 'Role',
        entityId: role.id,
        expectedRevision: role.revision,
        storedRevision: roles[index].revision,
      );
    }
    final stored = Role.fromJson({
      ...role.toJson(),
      'revision': index < 0 ? 0 : roles[index].revision + 1,
    });
    index < 0 ? roles.add(stored) : roles[index] = stored;
    return stored;
  }

  @override
  Future<bool> delete(Id id, {required MutationMetadata metadata}) async {
    final before = roles.length;
    roles.removeWhere((role) => role.id == id);
    return roles.length < before;
  }

  @override
  Future<bool> installSystemRole(Role role) =>
      throw UnimplementedError('not used by handlers');
}

/// In-memory [ModelCatalogRepository] for handler tests; a stale save throws
/// [StaleRevisionError] like the real one.
class StubModelCatalogRepository implements ModelCatalogRepository {
  final Map<Id, ModelCatalog> models = {};

  @override
  Future<ModelCatalog?> findById(Id id) async => models[id];

  @override
  Future<List<ModelCatalog>> listForOwner(Id ownerAccountId) async => [
    for (final m in models.values)
      if (m.ownerAccountId == ownerAccountId) m,
  ];

  @override
  Future<List<ModelCatalog>> listForProfile(Id participantProfileId) async => [
    for (final m in models.values)
      if (m.participantProfileId == participantProfileId) m,
  ]..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<ModelCatalog> save(
    ModelCatalog entry, {
    required MutationMetadata metadata,
  }) async {
    final current = models[entry.id];
    if (current != null && current.revision != entry.revision) {
      throw StaleRevisionError(
        entityType: 'ModelCatalog',
        entityId: entry.id,
        expectedRevision: entry.revision,
        storedRevision: current.revision,
      );
    }
    final stored = ModelCatalog.fromJson({
      ...entry.toJson(),
      'revision': current == null ? 0 : current.revision + 1,
    });
    models[entry.id] = stored;
    return stored;
  }

  @override
  Future<bool> delete(Id id, {required MutationMetadata metadata}) async =>
      models.remove(id) != null;
}

/// In-memory [ContestModelLinkRepository] for handler tests; a stale save
/// throws [StaleRevisionError] like the real one.
class StubContestModelLinkRepository implements ContestModelLinkRepository {
  final Map<Id, ContestModelLink> links = {};

  @override
  Future<ContestModelLink?> findById(Id id) async => links[id];

  @override
  Future<List<ContestModelLink>> listForParticipation(
    Id contestParticipationId,
  ) async => [
    for (final l in links.values)
      if (l.contestParticipationId == contestParticipationId) l,
  ];

  @override
  Future<List<ContestModelLink>> listForContest(Id contestId) async => [
    for (final l in links.values)
      if (l.contestId == contestId) l,
  ];

  @override
  Future<ContestModelLink> save(
    ContestModelLink link, {
    required MutationMetadata metadata,
  }) async {
    final current = links[link.id];
    if (current != null && current.revision != link.revision) {
      throw StaleRevisionError(
        entityType: 'ContestModelLink',
        entityId: link.id,
        expectedRevision: link.revision,
        storedRevision: current.revision,
      );
    }
    final stored = ContestModelLink.fromJson({
      ...link.toJson(),
      'revision': current == null ? 0 : current.revision + 1,
    });
    links[link.id] = stored;
    return stored;
  }

  @override
  Future<bool> delete(Id id, {required MutationMetadata metadata}) async =>
      links.remove(id) != null;
}
