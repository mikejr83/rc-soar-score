import 'package:equatable/equatable.dart';

/// Which headline the progress card shows.
enum ProgressStage {
  /// The matrix is not drawn.
  noMatrix,

  /// A matrix exists but the scores could not be read.
  scoresUnavailable,

  /// A matrix exists and nothing is scored yet.
  noScores,

  /// Scoring has started and the contest is not completed.
  inProgress,

  /// The contest is completed.
  finished,
}

/// The "where we are" line of the progress card, as plain values; the widget
/// formats the group letter and the time in the contest time zone.
class ProgressHeadline extends Equatable {
  const ProgressHeadline({
    required this.stage,
    this.roundCount = 0,
    this.groupCount = 0,
    this.groupSizeMin = 0,
    this.groupSizeMax = 0,
    this.matrixRevision,
    this.currentRound,
    this.totalRounds = 0,
    this.currentGroup,
    this.groupsInCurrentRound,
    this.latestScoreAt,
    this.roundsFlown = 0,
    this.scoreCount = 0,
  });

  final ProgressStage stage;

  /// For [ProgressStage.noScores]: the drawn matrix.
  final int roundCount;
  final int groupCount;
  final int groupSizeMin;
  final int groupSizeMax;
  final int? matrixRevision;

  /// For [ProgressStage.inProgress]: the latest round that has a score, of
  /// [totalRounds] (the planned total when the draw is seeded).
  final int? currentRound;
  final int totalRounds;

  /// The group of the latest score in [currentRound] and how many groups the
  /// round has.
  final int? currentGroup;
  final int? groupsInCurrentRound;

  /// When the most recent official score was set, if known.
  final DateTime? latestScoreAt;

  /// For [ProgressStage.finished]: rounds with at least one score, and the
  /// number of scores.
  final int roundsFlown;
  final int scoreCount;

  /// True when every round of the contest has a score.
  bool get allRoundsFlown => totalRounds > 0 && roundsFlown >= totalRounds;

  @override
  List<Object?> get props => [
    stage,
    roundCount,
    groupCount,
    groupSizeMin,
    groupSizeMax,
    matrixRevision,
    currentRound,
    totalRounds,
    currentGroup,
    groupsInCurrentRound,
    latestScoreAt,
    roundsFlown,
    scoreCount,
  ];
}
