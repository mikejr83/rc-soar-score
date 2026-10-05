import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/authority.dart';
import '../id.dart';
import '../shared/shared.dart';
import 'score_components.dart';

part 'score_attempt.g.dart';

/// The immutable raw submission of score data for a placeholder.
///
/// Append-only, so it has no row revision. See
/// `plan/data-model/entities/score_attempt.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class ScoreAttempt extends Equatable implements AppendOnly {
  ScoreAttempt({
    required this.id,
    required this.contestId,
    required this.scorePlaceholderId,
    required this.configRevisionId,
    required this.matrixRevisionId,
    required Map<String, Object?> rawComponents,
    required this.actorId,
    required this.authority,
    this.invitationId,
    this.sourceDevice,
    required String clientMutationId,
    required this.baseScoreRevision,
  }) : rawComponents = Map.unmodifiable(rawComponents),
       clientMutationId = requireNotBlank(
         clientMutationId,
         'clientMutationId',
       ) {
    requireValidPenalties(rawComponents, authority: authority);
    requireNonNegative(baseScoreRevision, 'baseScoreRevision');
  }

  factory ScoreAttempt.fromJson(Map<String, Object?> json) =>
      _$ScoreAttemptFromJson(json);

  @override
  final Id id;
  final Id contestId;
  final Id scorePlaceholderId;

  /// The configuration revision the client held; informational only.
  final Id configRevisionId;

  final Id matrixRevisionId;

  /// Raw submitted components in their original units.
  final Map<String, Object?> rawComponents;

  final Id actorId;
  final Authority authority;

  /// The invitation the entry was submitted under, if any.
  final Id? invitationId;

  final String? sourceDevice;

  /// Client-side dedup key, unique per attempt.
  final String clientMutationId;

  /// The score revision this attempt was based on.
  final int baseScoreRevision;

  @override
  String get entityType => 'ScoreAttempt';

  @override
  SyncScope get syncScope => SyncScope.contest;

  Map<String, Object?> toJson() => _$ScoreAttemptToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    scorePlaceholderId,
    configRevisionId,
    matrixRevisionId,
    rawComponents,
    actorId,
    authority,
    invitationId,
    sourceDevice,
    clientMutationId,
    baseScoreRevision,
  ];
}
