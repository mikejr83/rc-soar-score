import 'package:equatable/equatable.dart';

import '../enums/authority.dart';
import '../enums/selection_origin.dart';
import '../models/id.dart';

/// What became of one submission to a score slot.
enum ScoreHistoryOutcome {
  /// The official score now.
  current('current'),

  /// An official score that a later revision replaced.
  superseded('superseded'),

  /// A submission that never became official, for example a participant's
  /// entry that lost to the director's decision.
  notAdopted('not_adopted'),

  /// The newest submission, still waiting for the director's decision.
  pending('pending');

  const ScoreHistoryOutcome(this.wire);

  final String wire;

  static ScoreHistoryOutcome parse(String wire) =>
      values.firstWhere((outcome) => outcome.wire == wire);
}

// The wire text of an authority is its name with a capital letter, as in
// `plan/data-model/enumerations.md`.
String _authorityWire(Authority authority) =>
    authority.name[0].toUpperCase() + authority.name.substring(1);

Authority _parseAuthority(String wire) =>
    Authority.values.firstWhere((a) => _authorityWire(a) == wire);

String _originWire(SelectionOrigin origin) =>
    origin.name[0].toUpperCase() + origin.name.substring(1);

SelectionOrigin _parseOrigin(String wire) =>
    SelectionOrigin.values.firstWhere((o) => _originWire(o) == wire);

/// One submission to a score slot: an official revision, or an attempt that
/// did not become one.
class ScoreHistoryEntry extends Equatable {
  const ScoreHistoryEntry({
    required this.attemptId,
    required this.outcome,
    required this.components,
    required this.actorId,
    required this.authority,
    this.selectionOrigin,
    this.scoreRevision,
    this.reason,
    this.at,
    this.reviewClosed = false,
  });

  factory ScoreHistoryEntry.fromJson(Map<String, Object?> json) =>
      ScoreHistoryEntry(
        attemptId: Id.parse(json['attempt_id']! as String),
        outcome: ScoreHistoryOutcome.parse(json['outcome']! as String),
        scoreRevision: json['score_revision'] as int?,
        components: Map<String, Object?>.from(
          json['components']! as Map<Object?, Object?>,
        ),
        reason: json['reason'] as String?,
        actorId: json['actor_id'] == null
            ? null
            : Id.parse(json['actor_id']! as String),
        authority: _parseAuthority(json['authority']! as String),
        selectionOrigin: json['selection_origin'] == null
            ? null
            : _parseOrigin(json['selection_origin']! as String),
        at: json['at'] == null ? null : DateTime.parse(json['at']! as String),
        reviewClosed: json['review_closed'] as bool? ?? false,
      );

  final Id attemptId;
  final ScoreHistoryOutcome outcome;

  /// The official revision number; null for a submission that did not become
  /// official.
  final int? scoreRevision;

  /// The official components, or the submitted ones when not adopted.
  final Map<String, Object?> components;

  /// Why the revision was set; null for a submission that was not adopted.
  final String? reason;

  /// Who made the revision official; null when the contest accepted it on
  /// its own, and for an attempt that has no actor.
  final Id? actorId;

  /// The authority of the submission itself, not of whoever adopted it.
  final Authority authority;

  /// How the revision was selected; null for a submission that did not
  /// become official.
  final SelectionOrigin? selectionOrigin;

  /// When the revision was set (UTC); null for a submission that was not
  /// adopted, which carries no time.
  final DateTime? at;

  /// True for the current official version when a director's decision closed
  /// review of it: a manual or review-decision version, or an automatically
  /// accepted one the director confirmed (`ScorePlaceholder.isReviewClosed`).
  /// A lock is separate and not included.
  final bool reviewClosed;

  Map<String, Object?> toJson() => {
    'attempt_id': attemptId.value,
    'outcome': outcome.wire,
    'score_revision': scoreRevision,
    'components': components,
    'reason': reason,
    'actor_id': actorId?.value,
    'authority': _authorityWire(authority),
    'selection_origin': selectionOrigin == null
        ? null
        : _originWire(selectionOrigin!),
    'at': at?.toUtc().toIso8601String(),
    'review_closed': reviewClosed,
  };

  @override
  List<Object?> get props => [
    attemptId,
    outcome,
    scoreRevision,
    components,
    reason,
    actorId,
    authority,
    selectionOrigin,
    at,
    reviewClosed,
  ];
}

/// Every submission to one score slot, oldest first: the official revisions
/// with their reasons, and the attempts that did not become official.
class ScoreHistory extends Equatable {
  ScoreHistory({
    required this.assignmentId,
    Iterable<ScoreHistoryEntry> entries = const [],
  }) : entries = List.unmodifiable(entries);

  factory ScoreHistory.fromJson(Map<String, Object?> json) => ScoreHistory(
    assignmentId: Id.parse(json['assignment_id']! as String),
    entries: [
      for (final entry in json['entries']! as List<Object?>)
        ScoreHistoryEntry.fromJson(entry! as Map<String, Object?>),
    ],
  );

  final Id assignmentId;
  final List<ScoreHistoryEntry> entries;

  Map<String, Object?> toJson() => {
    'assignment_id': assignmentId.value,
    'entries': [for (final entry in entries) entry.toJson()],
  };

  @override
  List<Object?> get props => [assignmentId, entries];
}
