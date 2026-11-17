import 'package:equatable/equatable.dart';

import '../id.dart';

/// A `promote_score` intent that waits for the service's decision.
///
/// It is the pending projection of a mark-official on a syncing installation:
/// the slot shows the adoption as waiting, never as an official score.
class PendingPromotion extends Equatable {
  const PendingPromotion({
    required this.operationId,
    required this.contestId,
    required this.assignmentId,
    required this.sourceAttemptId,
    required this.expectedScoreRevision,
    required this.queuedAt,
  });

  factory PendingPromotion.fromJson(Map<String, Object?> json) =>
      PendingPromotion(
        operationId: Id.parse(json['operation_id']! as String),
        contestId: Id.parse(json['contest_id']! as String),
        assignmentId: Id.parse(json['assignment_id']! as String),
        sourceAttemptId: Id.parse(json['source_attempt_id']! as String),
        expectedScoreRevision: json['expected_score_revision']! as int,
        queuedAt: DateTime.parse(json['queued_at']! as String),
      );

  /// The intent's operation id; it is stored with the intent, so a retry
  /// after a restart carries the same id.
  final Id operationId;
  final Id contestId;
  final Id assignmentId;
  final Id sourceAttemptId;
  final int expectedScoreRevision;
  final DateTime queuedAt;

  Map<String, Object?> toJson() => {
    'operation_id': operationId.value,
    'contest_id': contestId.value,
    'assignment_id': assignmentId.value,
    'source_attempt_id': sourceAttemptId.value,
    'expected_score_revision': expectedScoreRevision,
    'queued_at': queuedAt.toUtc().toIso8601String(),
  };

  @override
  List<Object?> get props => [
    operationId,
    contestId,
    assignmentId,
    sourceAttemptId,
    expectedScoreRevision,
    queuedAt,
  ];
}
