import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/selection_origin.dart';
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
    this.setBy,
    required String reason,
    this.selectionOrigin = SelectionOrigin.manual,
  }) : components = Map.unmodifiable(components),
       setAt = setAt.toUtc(),
       reason = requireNotBlank(reason, 'reason') {
    requirePositive(scoreRevision, 'scoreRevision');
    requireValidPenalties(components);
    if ((selectionOrigin == SelectionOrigin.automatic) != (setBy == null)) {
      throw ArgumentError(
        'set_by is null exactly when the selection origin is Automatic',
      );
    }
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

  /// The director who made it official; null when the contest accepted it on
  /// its own ([SelectionOrigin.automatic]), which is system authority.
  final Id? setBy;

  /// A stable code localized where it is shown.
  final String reason;

  /// How this version was selected. Official status alone never says.
  /// Records written before the field existed read as manual.
  @JsonKey(defaultValue: SelectionOrigin.manual)
  final SelectionOrigin selectionOrigin;

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
    selectionOrigin,
  ];
}
