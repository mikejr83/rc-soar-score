import 'package:soar_score_core/soar_score_core.dart' as core;

/// Schema version of the payloads this package writes into `MutationRecord`.
const mutationPayloadVersion = 1;

/// `MutationRecord.payload` for a save: the entity as the model wrote it.
Map<String, Object?> savePayload(Map<String, Object?> entity) =>
    core.VersionedPayload(
      version: mutationPayloadVersion,
      data: {'operation': 'save', 'entity': entity},
    ).toJson();

/// `MutationRecord.payload` for a delete.
Map<String, Object?> deletePayload() => core.VersionedPayload(
  version: mutationPayloadVersion,
  data: const {'operation': 'delete'},
).toJson();
