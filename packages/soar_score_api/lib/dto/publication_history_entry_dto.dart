import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'publication_history_entry_dto.g.dart';

/// One projection of a publication in
/// `GET /api/v1/contests/{id}/publication/projections`, newest first.
///
/// [publishedBy] is the account stored on the projection (null for an
/// anonymous publish). [publisherKind] is `person` when the director asked
/// for the publish and `system` when the update mode published after a
/// score entry; an automatic publish still carries the owner in
/// [publishedBy].
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class PublicationHistoryEntryDto {
  const PublicationHistoryEntryDto({
    required this.id,
    required this.projectionRevision,
    required this.contestRevision,
    required this.publishedAt,
    required this.publishedBy,
    required this.publisherKind,
  });

  factory PublicationHistoryEntryDto.fromJson(Map<String, dynamic> json) =>
      _$PublicationHistoryEntryDtoFromJson(json);

  final Id id;
  final int projectionRevision;
  final int contestRevision;
  final DateTime publishedAt;
  final Id? publishedBy;
  final String publisherKind;

  bool get isBySystem => publisherKind == 'system';

  Map<String, dynamic> toJson() => _$PublicationHistoryEntryDtoToJson(this);
}
