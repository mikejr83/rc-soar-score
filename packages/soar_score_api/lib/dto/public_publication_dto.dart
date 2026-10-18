import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'public_publication_dto.g.dart';

/// The answer to `GET /public/publications/{id}`: a published contest as the
/// public sees it.
///
/// The nested [contest], [participants], [teams], [matrix], [scores],
/// [standings] and [calculation] members are kept as served; the pages that
/// read them shape them (#434, #435, #436).
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class PublicPublicationDto {
  const PublicPublicationDto({
    required this.publicationId,
    required this.visibility,
    required this.projectionRevision,
    required this.publishedAt,
    required this.contest,
    required this.disciplineType,
    required this.calculationVersion,
    this.resultsHiddenThroughRound,
    this.participants = const [],
    this.teams = const [],
    this.matrix,
    this.scores = const [],
    this.standings = const {'rounds': <Object?>[]},
    this.calculation,
  });

  factory PublicPublicationDto.fromJson(Map<String, dynamic> json) =>
      _$PublicPublicationDtoFromJson(json);

  final Id publicationId;

  /// `Unlisted` or `Public`.
  final String visibility;
  final int projectionRevision;
  final DateTime publishedAt;
  final Map<String, Object?> contest;
  final String disciplineType;
  final String calculationVersion;

  /// The last round whose standings are shown, or null when none are hidden.
  final int? resultsHiddenThroughRound;

  /// One entry per pilot: the key, display data and `details`, which is null
  /// for a redacted pilot.
  final List<Object?> participants;
  final List<Object?> teams;
  final Map<String, Object?>? matrix;
  final List<Object?> scores;

  /// `{'rounds': [...]}`: the standings after each completed round up to the
  /// hiding limit.
  final Map<String, Object?> standings;
  final Map<String, Object?>? calculation;

  Map<String, dynamic> toJson() => _$PublicPublicationDtoToJson(this);
}
