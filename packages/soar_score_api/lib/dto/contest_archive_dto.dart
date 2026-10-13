import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'contest_archive_dto.g.dart';

/// A complete contest, as returned by `GET /api/v1/contests/{id}/download`
/// and `.../export`, and as sent to `POST /api/v1/contests/import`.
///
/// [data] holds the entities by table name; an export adds raw score
/// revisions, audit history, conflicts, tombstones, pending mutations and
/// publication references. Import keeps every identifier.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class ContestArchiveDto {
  const ContestArchiveDto({
    required this.protocolVersion,
    required this.schemaVersion,
    required this.contestId,
    required this.serverSequence,
    required this.data,
  });

  factory ContestArchiveDto.fromJson(Map<String, dynamic> json) =>
      _$ContestArchiveDtoFromJson(json);

  final int protocolVersion;
  final int schemaVersion;
  final Id contestId;

  /// The scope sequence the archive was taken at; a restored installation
  /// starts its cursor here.
  final int serverSequence;

  final Map<String, Object?> data;

  Map<String, dynamic> toJson() => _$ContestArchiveDtoToJson(this);
}
