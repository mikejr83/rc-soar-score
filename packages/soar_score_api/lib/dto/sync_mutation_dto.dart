import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'sync_mutation_dto.g.dart';

/// One unsent mutation in a sync exchange request.
///
/// The service applies a mutation at most once, keyed by [clientMutationId]
/// within the scope. [baseRevision] is null for a creation. [payload] is the
/// entity state or delta at the time of the change.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class SyncMutationDto {
  const SyncMutationDto({
    required this.id,
    required this.clientMutationId,
    required this.entityType,
    required this.entityId,
    required this.authority,
    required this.clientTime,
    required this.payload,
    this.baseRevision,
    this.dependsOnMutationId,
  });

  factory SyncMutationDto.fromJson(Map<String, dynamic> json) =>
      _$SyncMutationDtoFromJson(json);

  final Id id;
  final String clientMutationId;
  final String entityType;
  final Id entityId;
  final int? baseRevision;
  final Authority authority;

  /// Audit only; the service never uses it to order or resolve changes.
  final DateTime clientTime;

  /// The mutation this one depends on; it appears earlier in the request.
  final Id? dependsOnMutationId;

  final Map<String, Object?> payload;

  Map<String, dynamic> toJson() => _$SyncMutationDtoToJson(this);
}
