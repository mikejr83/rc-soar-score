import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'public_publication_summary_dto.g.dart';

/// One line of `GET /public/publications`: a Public publication as the
/// listing shows it, newest first.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class PublicPublicationSummaryDto {
  const PublicPublicationSummaryDto({
    required this.publicationId,
    required this.publishedAt,
    required this.projectionRevision,
    required this.contest,
    required this.disciplineType,
  });

  factory PublicPublicationSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$PublicPublicationSummaryDtoFromJson(json);

  final Id publicationId;
  final DateTime publishedAt;
  final int projectionRevision;

  /// The projection's contest identity: name, dates, time zone, place.
  final Map<String, Object?> contest;
  final String disciplineType;

  Map<String, dynamic> toJson() => _$PublicPublicationSummaryDtoToJson(this);
}
