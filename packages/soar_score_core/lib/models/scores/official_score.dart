import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';
import 'score_components.dart';

part 'official_score.g.dart';

/// One version of the authoritative score components for a placeholder.
///
/// Versions are kept; the latest `scoreRevision` is current. It has no row
/// revision. See `plan/data-model/entities/official_score.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class OfficialScore extends Equatable implements AppendOnly {
  OfficialScore({
    required this.id,
    required this.contestId,
    required this.scorePlaceholderId,
    required this.scoreAttemptId,
    required this.scoreRevision,
    required Map<String, Object?> components,
    required DateTime setAt,
    required this.setBy,
    required String reason,
  }) : components = Map.unmodifiable(components),
       setAt = setAt.toUtc(),
       reason = requireNotBlank(reason, 'reason') {
    requirePositive(scoreRevision, 'scoreRevision');
    requireValidPenalties(components);
  }

  factory OfficialScore.fromJson(Map<String, Object?> json) =>
      _$OfficialScoreFromJson(json);

  @override
  final Id id;
  final Id contestId;
  final Id scorePlaceholderId;

  /// The attempt that produced this score.
  final Id scoreAttemptId;

  /// This version's number; unique per placeholder.
  final int scoreRevision;

  /// Authoritative inputs; calculated values live in the flight result.
  final Map<String, Object?> components;

  final DateTime setAt;
  final Id setBy;
  final String reason;

  @override
  String get entityType => 'OfficialScore';

  @override
  SyncScope get syncScope => SyncScope.contest;

  Map<String, Object?> toJson() => _$OfficialScoreToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    scorePlaceholderId,
    scoreAttemptId,
    scoreRevision,
    components,
    setAt,
    setBy,
    reason,
  ];
}
