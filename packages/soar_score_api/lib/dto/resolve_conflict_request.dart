import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'resolve_conflict_request.g.dart';

/// Body of `POST /api/v1/sync/conflicts/{conflictId}/resolve`.
///
/// Itself a mutation: [clientMutationId] makes it idempotent. [payload] is
/// the merged value and is sent only for `Merged`.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
)
class ResolveConflictRequest {
  const ResolveConflictRequest({
    required this.clientMutationId,
    required this.choice,
    this.payload,
  });

  factory ResolveConflictRequest.fromJson(Map<String, dynamic> json) =>
      _$ResolveConflictRequestFromJson(json);

  final String clientMutationId;
  final ConflictResolutionChoice choice;
  final Map<String, Object?>? payload;

  Map<String, dynamic> toJson() => _$ResolveConflictRequestToJson(this);
}
