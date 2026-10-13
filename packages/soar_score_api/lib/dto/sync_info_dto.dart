import 'package:json_annotation/json_annotation.dart';

part 'sync_info_dto.g.dart';

/// Response of `GET /api/v1/sync/info`: the version ranges the service
/// accepts and its clock.
@JsonSerializable(checked: true, fieldRename: FieldRename.snake)
class SyncInfoDto {
  const SyncInfoDto({
    required this.protocolVersion,
    required this.minProtocolVersion,
    required this.minSchemaVersion,
    required this.maxSchemaVersion,
    required this.serverTime,
  });

  factory SyncInfoDto.fromJson(Map<String, dynamic> json) =>
      _$SyncInfoDtoFromJson(json);

  /// The newest protocol version the service speaks.
  final int protocolVersion;
  final int minProtocolVersion;
  final int minSchemaVersion;
  final int maxSchemaVersion;
  final DateTime serverTime;

  /// Whether a client at these versions can sync.
  bool accepts({required int protocol, required int schema}) =>
      protocol >= minProtocolVersion &&
      protocol <= protocolVersion &&
      schema >= minSchemaVersion &&
      schema <= maxSchemaVersion;

  Map<String, dynamic> toJson() => _$SyncInfoDtoToJson(this);
}
