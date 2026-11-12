import 'package:soar_score_core/soar_score_core.dart' as core;

/// Schema version of the payloads this package writes into `MutationRecord`.
const mutationPayloadVersion = 1;

/// `MutationRecord.payload` for a save: the entity as the model wrote it.
Map<String, Object?> savePayload(
  Map<String, Object?> entity, {
  core.Id? follows,
}) => core.VersionedPayload(
  version: mutationPayloadVersion,
  data: {'operation': 'save', 'entity': entity, 'follows': ?follows?.value},
).toJson();

/// `MutationRecord.payload` for a delete.
Map<String, Object?> deletePayload() => core.VersionedPayload(
  version: mutationPayloadVersion,
  data: const {'operation': 'delete'},
).toJson();

/// `MutationRecord.payload` for moving an assignment: the new `Moved` row, and
/// the id of the assignment it supersedes, which the receiver marks too.
Map<String, Object?> moveAssignmentPayload(
  Map<String, Object?> entity,
  String supersedes,
) => core.VersionedPayload(
  version: mutationPayloadVersion,
  data: {'operation': 'save', 'entity': entity, 'supersedes': supersedes},
).toJson();

/// `MutationRecord.payload` for a new landing table: the table row, with its
/// entries under `results`, so one mutation replicates the whole table.
Map<String, Object?> landingTablePayload(
  Map<String, Object?> table,
  List<Map<String, Object?>> results,
) => savePayload({...table, 'results': results});
