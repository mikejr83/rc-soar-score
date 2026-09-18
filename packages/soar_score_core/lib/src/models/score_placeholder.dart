import 'score_attempt.dart';

/// Represents a score placeholder for a participant assignment.
///
/// A score placeholder exists before entry and distinguishes various states
/// including NotEntered, draft, submitted, zero, retired, review, official,
/// and locked.
class ScorePlaceholder {
  final String id;
  final String assignmentId;
  final String pilotId;
  final int scheduledRound;
  final int? creditedRound;
  final String? group;
  final String scoreState;
  final ScoreAttempt? currentOfficial;

  ScorePlaceholder({
    required this.id,
    required this.assignmentId,
    required this.pilotId,
    required this.scheduledRound,
    this.creditedRound,
    this.group,
    required this.scoreState,
    this.currentOfficial,
  });
}