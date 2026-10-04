import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/discipline_type.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'publication_projection.g.dart';

/// An immutable snapshot of a contest's public data at one publish time.
///
/// Backend only. Pilots appear only by an opaque key; identifying details
/// live in `PublicationParticipant`. The projection holds no private data.
/// See `plan/data-model/entities/publication_projection.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class PublicationProjection extends Equatable implements BackendOnly {
  PublicationProjection({
    required this.id,
    required this.publicationId,
    required this.projectionRevision,
    required this.contestRevision,
    required this.configRevision,
    required this.matrixRevision,
    required this.disciplineType,
    required this.disciplineRulesVersion,
    required String calculationVersion,
    required Map<String, Object?> contestIdentity,
    List<Object?>? participants,
    List<Object?>? teams,
    Map<String, Object?>? matrixInfo,
    List<Object?>? scores,
    Map<String, Object?>? standings,
    Map<String, Object?>? calculationMetadata,
    required DateTime publishedAt,
    this.publishedBy,
    required String clientMutationId,
  }) : calculationVersion = requireNotBlank(
         calculationVersion,
         'calculationVersion',
       ),
       contestIdentity = Map.unmodifiable(contestIdentity),
       participants = participants == null
           ? null
           : List.unmodifiable(participants),
       teams = teams == null ? null : List.unmodifiable(teams),
       matrixInfo = matrixInfo == null ? null : Map.unmodifiable(matrixInfo),
       scores = scores == null ? null : List.unmodifiable(scores),
       standings = standings == null ? null : Map.unmodifiable(standings),
       calculationMetadata = calculationMetadata == null
           ? null
           : Map.unmodifiable(calculationMetadata),
       publishedAt = publishedAt.toUtc(),
       clientMutationId = requireNotBlank(
         clientMutationId,
         'clientMutationId',
       ) {
    requirePositive(projectionRevision, 'projectionRevision');
    requireNonNegative(contestRevision, 'contestRevision');
    requireNonNegative(configRevision, 'configRevision');
    requireNonNegative(matrixRevision, 'matrixRevision');
    requirePositive(disciplineRulesVersion, 'disciplineRulesVersion');
  }

  factory PublicationProjection.fromJson(Map<String, Object?> json) =>
      _$PublicationProjectionFromJson(json);

  final Id id;
  final Id publicationId;

  /// Sequential number within the publication, from 1.
  final int projectionRevision;

  final int contestRevision;
  final int configRevision;
  final int matrixRevision;
  final DisciplineType disciplineType;
  final int disciplineRulesVersion;
  final String calculationVersion;

  /// Name, dates, time zone, host, location and discipline name.
  final Map<String, Object?> contestIdentity;

  /// One entry per pilot, by `pilot_key`; no identifying details.
  final List<Object?>? participants;

  final List<Object?>? teams;
  final Map<String, Object?>? matrixInfo;
  final List<Object?>? scores;
  final Map<String, Object?>? standings;
  final Map<String, Object?>? calculationMetadata;
  final DateTime publishedAt;

  /// Null for an anonymous publish.
  final Id? publishedBy;

  /// Idempotency key, unique within the publication.
  final String clientMutationId;

  Map<String, Object?> toJson() => _$PublicationProjectionToJson(this);

  @override
  List<Object?> get props => [
    id,
    publicationId,
    projectionRevision,
    contestRevision,
    configRevision,
    matrixRevision,
    disciplineType,
    disciplineRulesVersion,
    calculationVersion,
    contestIdentity,
    participants,
    teams,
    matrixInfo,
    scores,
    standings,
    calculationMetadata,
    publishedAt,
    publishedBy,
    clientMutationId,
  ];
}
