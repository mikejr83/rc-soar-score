import '../enums/lifecycle_state.dart';
import '../enums/role_type.dart';
import '../errors/contest_state_error.dart';
import '../errors/entity_not_found_error.dart';
import '../models/id.dart';
import '../models/participants/contest_participation.dart';
import '../models/teams/contest_model_link.dart';
import '../models/teams/model_catalog.dart';
import '../repositories/already_stored_error.dart';
import '../repositories/mutation_metadata.dart';
import '../repositories/repository.dart';
import '../repositories/stale_revision_error.dart';

/// The model operations of the API: a participant profile's own models, and
/// the models a pilot flies in a contest.
///
/// A profile's models ([ModelCatalog]) are private to the director who owns
/// the profile; every operation takes that director's account id and treats
/// anyone else's profile as not found. A contest's links ([ContestModelLink])
/// are snapshots: editing the profile's model afterwards does not change
/// them. Missing models are never an error.
class ModelsService {
  ModelsService(this.repository);

  final Repository repository;

  /// The models of profile [profileId] owned by [ownerAccountId], by name.
  Future<List<ModelCatalog>> listProfileModels(
    Id ownerAccountId,
    Id profileId,
  ) async {
    await _requireProfile(ownerAccountId, profileId);
    return repository.modelCatalogRepository.listForProfile(profileId);
  }

  /// Adds a model to profile [profileId].
  ///
  /// Idempotent on [id]: repeating the same request returns the stored model.
  /// The same id with different content, or another model of the profile with
  /// the same name and manufacturer, throws an [AlreadyStoredError]. A blank
  /// name or model id throws an [ArgumentError].
  Future<ModelCatalog> addProfileModel(
    Id ownerAccountId,
    Id profileId, {
    required Id id,
    required String name,
    String? manufacturer,
    String? modelId,
    required MutationMetadata metadata,
  }) async {
    await _requireProfile(ownerAccountId, profileId);
    final model = _catalog(
      id: id,
      ownerAccountId: ownerAccountId,
      profileId: profileId,
      name: name,
      manufacturer: manufacturer,
      modelId: modelId,
    );
    final models = repository.modelCatalogRepository;
    final stored = await models.findById(id);
    if (stored != null) {
      if (stored.ownerAccountId == ownerAccountId &&
          stored.participantProfileId == profileId &&
          stored.name == model.name &&
          stored.manufacturer == model.manufacturer &&
          stored.modelId == model.modelId) {
        return stored;
      }
      throw AlreadyStoredError(entityType: 'ModelCatalog', entityId: id);
    }
    await _requireNoTwin(profileId, model, except: null);
    return models.save(model, metadata: metadata);
  }

  /// Replaces the details of model [id] of profile [profileId].
  ///
  /// Contest snapshots are not touched. Throws a [StaleRevisionError] when
  /// [baseRevision] is not the stored revision.
  Future<ModelCatalog> updateProfileModel(
    Id ownerAccountId,
    Id profileId,
    Id id, {
    required String name,
    String? manufacturer,
    String? modelId,
    required int baseRevision,
    required MutationMetadata metadata,
  }) async {
    final stored = await _requireProfileModel(ownerAccountId, profileId, id);
    final model = _catalog(
      id: id,
      ownerAccountId: ownerAccountId,
      profileId: profileId,
      name: name,
      manufacturer: manufacturer,
      modelId: modelId,
      revision: baseRevision,
    );
    if (stored.revision != baseRevision) {
      throw StaleRevisionError(
        entityType: stored.entityType,
        entityId: id,
        expectedRevision: baseRevision,
        storedRevision: stored.revision,
      );
    }
    await _requireNoTwin(profileId, model, except: id);
    return repository.modelCatalogRepository.save(model, metadata: metadata);
  }

  /// Removes model [id] from profile [profileId]. Contest links keep their
  /// snapshot.
  Future<void> removeProfileModel(
    Id ownerAccountId,
    Id profileId,
    Id id, {
    required MutationMetadata metadata,
  }) async {
    await _requireProfileModel(ownerAccountId, profileId, id);
    await repository.modelCatalogRepository.delete(id, metadata: metadata);
  }

  /// Every model link of contest [contestId], by id.
  Future<List<ContestModelLink>> listLinks(Id contestId) async {
    await _requireContest(contestId);
    return repository.contestModelLinkRepository.listForContest(contestId);
  }

  /// Adds a model to the pilot [participationId] of contest [contestId].
  ///
  /// With [modelCatalogId] (a model of the pilot's profile) and no
  /// [modelName], the snapshot starts as a copy of that model; a
  /// [manufacturer] or [modelId] given overrides the copy. With a
  /// [modelName] the snapshot is what is given, and the catalog model is only
  /// remembered as its source. Without a catalog model, [modelName] is
  /// required.
  ///
  /// Idempotent on [id]: repeating the same request returns the stored link.
  /// The same id with different content throws an [AlreadyStoredError]. Only
  /// a pilot has models: any other role throws an [ArgumentError]. A
  /// Completed contest takes no change ([ContestStateError]).
  Future<ContestModelLink> addLink(
    Id contestId,
    Id ownerAccountId,
    Id participationId, {
    required Id id,
    Id? modelCatalogId,
    String? modelName,
    String? manufacturer,
    String? modelId,
    String? contestSpecificIdentifier,
    required MutationMetadata metadata,
  }) async {
    final participation = await _requireParticipation(
      contestId,
      participationId,
    );
    final stored = await repository.contestModelLinkRepository.findById(id);
    // A repeated request is answered even after the contest completed.
    if (stored == null) {
      await _requireOpen(contestId);
      _requirePilot(participation);
    }
    ModelCatalog? source;
    if (modelCatalogId != null) {
      source = await _requireProfileModel(
        ownerAccountId,
        participation.participantProfileId,
        modelCatalogId,
      );
    }
    // Without a name the link starts as a copy of the profile's model.
    final copying = source != null && _blankToNull(modelName) == null;
    final link = ContestModelLink(
      id: id,
      contestId: contestId,
      contestParticipationId: participationId,
      modelCatalogId: modelCatalogId,
      modelName: copying ? source.name : modelName ?? '',
      manufacturer:
          _blankToNull(manufacturer) ?? (copying ? source.manufacturer : null),
      modelId: _blankToNull(modelId) ?? (copying ? source.modelId : null),
      contestSpecificIdentifier: _blankToNull(contestSpecificIdentifier),
    );
    final links = repository.contestModelLinkRepository;
    if (stored != null) {
      if (_sameDetails(stored, link) &&
          stored.contestId == contestId &&
          stored.contestParticipationId == participationId) {
        return stored;
      }
      throw AlreadyStoredError(entityType: 'ContestModelLink', entityId: id);
    }
    return links.save(link, metadata: metadata);
  }

  /// Replaces the details of link [id] in contest [contestId]; the link to
  /// the profile's model stays as it was.
  ///
  /// Allowed after flights are scored (no score is recalculated), but not once
  /// the contest is Completed. Throws a
  /// [StaleRevisionError] when [baseRevision] is not the stored revision.
  Future<ContestModelLink> updateLink(
    Id contestId,
    Id id, {
    required String modelName,
    String? manufacturer,
    String? modelId,
    String? contestSpecificIdentifier,
    required int baseRevision,
    required MutationMetadata metadata,
  }) async {
    final stored = await _requireLink(contestId, id);
    await _requireOpen(contestId);
    if (stored.revision != baseRevision) {
      throw StaleRevisionError(
        entityType: stored.entityType,
        entityId: id,
        expectedRevision: baseRevision,
        storedRevision: stored.revision,
      );
    }
    return repository.contestModelLinkRepository.save(
      ContestModelLink(
        id: id,
        contestId: contestId,
        contestParticipationId: stored.contestParticipationId,
        modelCatalogId: stored.modelCatalogId,
        modelName: modelName,
        manufacturer: _blankToNull(manufacturer),
        modelId: _blankToNull(modelId),
        contestSpecificIdentifier: _blankToNull(contestSpecificIdentifier),
        revision: baseRevision,
      ),
      metadata: metadata,
    );
  }

  /// Removes link [id] from contest [contestId].
  Future<void> removeLink(
    Id contestId,
    Id id, {
    required MutationMetadata metadata,
  }) async {
    await _requireLink(contestId, id);
    await _requireOpen(contestId);
    await repository.contestModelLinkRepository.delete(id, metadata: metadata);
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

  Future<ModelCatalog> _requireProfileModel(
    Id ownerAccountId,
    Id profileId,
    Id id,
  ) async {
    await _requireProfile(ownerAccountId, profileId);
    final model = await repository.modelCatalogRepository.findById(id);
    if (model == null ||
        model.ownerAccountId != ownerAccountId ||
        model.participantProfileId != profileId) {
      throw EntityNotFoundError(entityType: 'ModelCatalog', entityId: id);
    }
    return model;
  }

  Future<void> _requireContest(Id contestId) async {
    if (await repository.contestRepository.findById(contestId) == null) {
      throw EntityNotFoundError(entityType: 'Contest', entityId: contestId);
    }
  }

  /// A Completed contest is history: its models are not changed.
  Future<void> _requireOpen(Id contestId) async {
    final contest = await repository.contestRepository.findById(contestId);
    if (contest?.lifecycleState == LifecycleState.completed) {
      throw ContestStateError(
        'contest_completed',
        'the models of a Completed contest are not changed',
      );
    }
  }

  Future<ContestParticipation> _requireParticipation(
    Id contestId,
    Id id,
  ) async {
    await _requireContest(contestId);
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

  Future<ContestModelLink> _requireLink(Id contestId, Id id) async {
    final link = await repository.contestModelLinkRepository.findById(id);
    if (link == null || link.contestId != contestId) {
      throw EntityNotFoundError(entityType: 'ContestModelLink', entityId: id);
    }
    return link;
  }

  void _requirePilot(ContestParticipation participation) {
    if (participation.roleType != RoleType.pilot) {
      throw ArgumentError.value(
        participation.id.value,
        'participationId',
        'is not a pilot; only pilots have models',
      );
    }
  }

  /// Refuses another model of the profile with the same name and
  /// manufacturer, which the store would refuse too.
  Future<void> _requireNoTwin(
    Id profileId,
    ModelCatalog model, {
    required Id? except,
  }) async {
    final models = await repository.modelCatalogRepository.listForProfile(
      profileId,
    );
    final twin = models
        .where(
          (m) =>
              m.id != except &&
              sameProfileModel(
                m,
                name: model.name,
                manufacturer: model.manufacturer,
              ),
        )
        .firstOrNull;
    if (twin != null) {
      throw AlreadyStoredError(entityType: 'ModelCatalog', entityId: twin.id);
    }
  }

  /// Whether [model] has this name and manufacturer, ignoring case: one
  /// profile holds a model once.
  static bool sameProfileModel(
    ModelCatalog model, {
    required String name,
    String? manufacturer,
  }) =>
      model.name.trim().toLowerCase() == name.trim().toLowerCase() &&
      (model.manufacturer ?? '').trim().toLowerCase() ==
          (manufacturer ?? '').trim().toLowerCase();

  static ModelCatalog _catalog({
    required Id id,
    required Id ownerAccountId,
    required Id profileId,
    required String name,
    String? manufacturer,
    String? modelId,
    int revision = 0,
  }) => ModelCatalog(
    id: id,
    ownerAccountId: ownerAccountId,
    participantProfileId: profileId,
    name: name.trim(),
    manufacturer: _blankToNull(manufacturer),
    modelId: _blankToNull(modelId),
    revision: revision,
  );

  static bool _sameDetails(ContestModelLink a, ContestModelLink b) =>
      a.modelCatalogId == b.modelCatalogId &&
      a.modelName == b.modelName &&
      a.manufacturer == b.manufacturer &&
      a.modelId == b.modelId &&
      a.contestSpecificIdentifier == b.contestSpecificIdentifier;

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
