import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'sync_revision_dto.g.dart';

/// Response of `GET /api/v1/sync/revision`: where a scope's log stands.
///
/// A client that talks to the service directly (the web app) compares
/// [sequence] with the one it last saw to learn whether anything changed
/// without reading the changes. Every accepted write moves it, including
/// pilots' self-scored attempts.
@JsonSerializable(
  checked: true,
  explicitToJson: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class SyncRevisionDto {
  const SyncRevisionDto({
    required this.accountId,
    required this.sequence,
    this.contestId,
  });

  factory SyncRevisionDto.fromJson(Map<String, dynamic> json) =>
      _$SyncRevisionDtoFromJson(json);

  /// The caller's account, which owns the director scope.
  final Id accountId;

  /// The contest asked about; null for the caller's own data scope.
  final Id? contestId;

  /// The scope's highest sequence; 0 before any change.
  final int sequence;

  Map<String, dynamic> toJson() => _$SyncRevisionDtoToJson(this);
}
