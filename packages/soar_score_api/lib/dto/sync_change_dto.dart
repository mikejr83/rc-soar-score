import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'sync_change_dto.g.dart';

/// One accepted change in a scope's stream, in sequence order.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class SyncChangeDto {
  const SyncChangeDto({
    required this.sequence,
    required this.entityType,
    required this.entityId,
    required this.revision,
    required this.payload,
  });

  factory SyncChangeDto.fromJson(Map<String, dynamic> json) =>
      _$SyncChangeDtoFromJson(json);

  final int sequence;
  final String entityType;
  final Id entityId;
  final int revision;
  final Map<String, Object?> payload;

  Map<String, dynamic> toJson() => _$SyncChangeDtoToJson(this);
}
