import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'model_entry.dart';

/// Where the models window keeps a pilot's models: in the wizard draft, or
/// in the stored contest through the API.
abstract interface class PilotModelsBackend {
  /// The models the person already has on their profile, for the picker.
  /// Empty when they cannot be read.
  Future<List<ModelCatalog>> profileModels();

  /// Enters [entry] for the pilot and returns it as stored.
  Future<ModelEntry> add(ModelEntry entry);

  /// Replaces the details of [entry] and returns it as stored.
  Future<ModelEntry> update(ModelEntry entry);

  Future<void> remove(ModelEntry entry);
}

/// Keeps the models in memory, for the wizard: they are sent when the
/// contest is created.
class DraftPilotModelsBackend implements PilotModelsBackend {
  DraftPilotModelsBackend({required this.loadProfileModels});

  final Future<List<ModelCatalog>> Function() loadProfileModels;

  @override
  Future<List<ModelCatalog>> profileModels() async {
    try {
      return await loadProfileModels();
    } on Object {
      // The picker is a convenience; typing a model still works.
      return const [];
    }
  }

  @override
  Future<ModelEntry> add(ModelEntry entry) async => entry;

  @override
  Future<ModelEntry> update(ModelEntry entry) async => entry;

  @override
  Future<void> remove(ModelEntry entry) async {}
}

/// Saves each change to the stored contest as it is made.
///
/// A model typed new is also added to the person's profile, so a later
/// contest can pick it.
class ApiPilotModelsBackend implements PilotModelsBackend {
  ApiPilotModelsBackend({
    required this.client,
    required this.contestId,
    required this.participationId,
    required this.profileId,
  });

  final ApiClient client;
  final Id contestId;
  final Id participationId;
  final Id profileId;

  List<ModelCatalog>? _profileModels;

  @override
  Future<List<ModelCatalog>> profileModels() async {
    try {
      return _profileModels ??= await client.profileModels(profileId);
    } on Object {
      return const [];
    }
  }

  @override
  Future<ModelEntry> add(ModelEntry entry) async {
    var catalogId = entry.catalogId;
    if (catalogId == null) {
      final models = [...await client.profileModels(profileId)];
      final known = models.where(
        (m) =>
            m.name.toLowerCase() == entry.name.toLowerCase() &&
            (m.manufacturer ?? '').toLowerCase() ==
                (entry.manufacturer ?? '').toLowerCase(),
      );
      if (known.isNotEmpty) {
        catalogId = known.first.id;
      } else {
        final created = await client.addProfileModel(
          profileId,
          AddProfileModelRequest(
            id: Id.create(),
            name: entry.name,
            manufacturer: entry.manufacturer,
            modelId: entry.modelId,
          ),
        );
        _profileModels = [...models, created];
        catalogId = created.id;
      }
    }
    final link = await client.addModelLink(
      contestId,
      participationId,
      AddModelLinkRequest(
        id: entry.id,
        modelCatalogId: catalogId,
        modelName: entry.name,
        manufacturer: entry.manufacturer,
        modelId: entry.modelId,
        contestSpecificIdentifier: entry.contestIdentifier,
      ),
    );
    return ModelEntry.fromLink(link);
  }

  @override
  Future<ModelEntry> update(ModelEntry entry) async => ModelEntry.fromLink(
    await client.updateModelLink(
      contestId,
      entry.id,
      UpdateModelLinkRequest(
        baseRevision: entry.revision,
        modelName: entry.name,
        manufacturer: entry.manufacturer,
        modelId: entry.modelId,
        contestSpecificIdentifier: entry.contestIdentifier,
      ),
    ),
  );

  @override
  Future<void> remove(ModelEntry entry) =>
      client.removeModelLink(contestId, entry.id);
}
