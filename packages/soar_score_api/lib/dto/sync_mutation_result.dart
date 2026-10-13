import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'sync_mutation_result.g.dart';

/// The service's decision for one submitted mutation.
///
/// `Accepted` carries [revision] and [sequence]. `Rejected` and `Conflict`
/// carry a [reasonCode] and the entity's [currentRevision]. `Skipped` names
/// the mutation it waited on in [dependsOn]. The same shape answers a
/// conflict resolution.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class SyncMutationResult {
  const SyncMutationResult({
    required this.clientMutationId,
    required this.outcome,
    this.revision,
    this.sequence,
    this.reasonCode,
    this.currentRevision,
    this.dependsOn,
  });

  factory SyncMutationResult.fromJson(Map<String, dynamic> json) =>
      _$SyncMutationResultFromJson(json);

  final String clientMutationId;
  final MutationOutcome outcome;
  final int? revision;
  final int? sequence;
  final String? reasonCode;
  final int? currentRevision;

  /// The `client_mutation_id` of the failed mutation this one depended on.
  final String? dependsOn;

  /// [reasonCode] as a known reason, or null when absent or from a newer
  /// service.
  SyncReasonCode? get reason => SyncReasonCode.tryParse(reasonCode);

  Map<String, dynamic> toJson() => _$SyncMutationResultToJson(this);
}
