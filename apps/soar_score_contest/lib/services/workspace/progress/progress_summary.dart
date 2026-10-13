import 'package:equatable/equatable.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../matrix/round_progress_view.dart';
import '../current_group_facts.dart';
import '../workspace_fact_source.dart';
import '../workspace_facts.dart';
import '../workspace_round_fact.dart';
import 'missing_round.dart';
import 'progress_headline.dart';
import 'progress_lag.dart';
import 'progress_tile.dart';

/// What the progress card (and the needs-attention missing-scores row) shows,
/// reduced from [WorkspaceFacts] to plain values.
///
/// Two rules decide everything here:
///
/// - The *frontier* is the latest round, by ordinal, that has a score. A later
///   correction of an earlier round does not move it.
/// - A round is *finished* once a later round has a score, or once the contest
///   is completed. A finished round that lacks scores (including one never
///   flown) is `missing`; the frontier round of a running contest that lacks
///   scores is `inProgress`, and its pending group is only a [lag] note.
///   Rounds after the frontier are `notFlown`, never missing.
class ProgressSummary extends Equatable {
  const ProgressSummary({
    required this.headline,
    this.tiles = const [],
    this.lag,
  });

  /// The summary for [facts].
  factory ProgressSummary.of(WorkspaceFacts facts) {
    if (!facts.hasMatrix) {
      return const ProgressSummary(
        headline: ProgressHeadline(stage: ProgressStage.noMatrix),
      );
    }
    return ProgressSummary.derive(
      rounds: facts.rounds,
      scoresAvailable: !facts.unavailable.contains(WorkspaceFactSource.scores),
      seeded: facts.drawMode == DrawMode.seededManOnMan,
      intendedTotalRounds: facts.intendedTotalRounds,
      roundCount: facts.roundCount,
      groupCount: facts.groupCount,
      groupSizeMin: facts.groupSizeMin,
      groupSizeMax: facts.groupSizeMax,
      matrixRevision: facts.matrix.revision?.revisionNumber,
      frontierGroup: facts.frontierGroup,
      latestScoreAt: facts.latestScore?.setAt,
      scoreCount: facts.scoreCount,
      completed: facts.contest.lifecycleState == LifecycleState.completed,
    );
  }

  /// The summary from plain values, so every case can be tested without a
  /// matrix. [rounds] holds every uncancelled round, in any order.
  factory ProgressSummary.derive({
    required List<WorkspaceRoundFact> rounds,
    required bool scoresAvailable,
    required bool seeded,
    int? intendedTotalRounds,
    required int roundCount,
    required int groupCount,
    required int groupSizeMin,
    required int groupSizeMax,
    int? matrixRevision,
    CurrentGroupFacts? frontierGroup,
    DateTime? latestScoreAt,
    required int scoreCount,
    required bool completed,
  }) {
    if (!scoresAvailable) {
      return const ProgressSummary(
        headline: ProgressHeadline(stage: ProgressStage.scoresUnavailable),
      );
    }
    final ordered = [...rounds]..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    int? frontier;
    for (final round in ordered) {
      if (round.scored > 0) {
        frontier = round.ordinal;
      }
    }

    final tiles = <ProgressTile>[
      for (final round in ordered) _tile(round, frontier, completed),
    ];
    final planned = seeded && intendedTotalRounds != null
        ? intendedTotalRounds
        : ordered.length;
    if (seeded && planned > ordered.length) {
      final last = ordered.isEmpty ? 0 : ordered.last.ordinal;
      for (var n = 1; n <= planned - ordered.length; n++) {
        tiles.add(
          ProgressTile(ordinal: last + n, state: ProgressTileState.notDrawn),
        );
      }
    }
    final totalRounds = planned > ordered.length ? planned : ordered.length;
    final flown = ordered.where((round) => round.scored > 0).length;

    final ProgressHeadline headline;
    if (completed && flown > 0) {
      headline = ProgressHeadline(
        stage: ProgressStage.finished,
        totalRounds: totalRounds,
        roundsFlown: flown,
        scoreCount: scoreCount,
        latestScoreAt: latestScoreAt,
      );
    } else if (frontier == null) {
      headline = ProgressHeadline(
        stage: ProgressStage.noScores,
        roundCount: roundCount,
        groupCount: groupCount,
        groupSizeMin: groupSizeMin,
        groupSizeMax: groupSizeMax,
        matrixRevision: matrixRevision,
        totalRounds: totalRounds,
      );
    } else {
      final group = frontierGroup?.roundOrdinal == frontier
          ? frontierGroup
          : null;
      headline = ProgressHeadline(
        stage: ProgressStage.inProgress,
        currentRound: frontier,
        totalRounds: totalRounds,
        currentGroup: group?.groupNumber,
        groupsInCurrentRound: group == null
            ? null
            : ordered.firstWhere((r) => r.ordinal == frontier).groupCount,
        latestScoreAt: latestScoreAt,
        roundsFlown: flown,
        scoreCount: scoreCount,
      );
    }

    ProgressLag? lag;
    final frontierTile = tiles
        .where((tile) => tile.ordinal == frontier)
        .firstOrNull;
    if (!completed &&
        frontierTile?.state == ProgressTileState.inProgress &&
        frontierGroup != null &&
        frontierGroup.roundOrdinal == frontier &&
        frontierGroup.total > 0 &&
        !frontierGroup.isComplete) {
      lag = ProgressLag(
        roundOrdinal: frontierGroup.roundOrdinal,
        groupNumber: frontierGroup.groupNumber,
        scored: frontierGroup.scored,
        total: frontierGroup.total,
      );
    }
    return ProgressSummary(headline: headline, tiles: tiles, lag: lag);
  }

  static ProgressTile _tile(
    WorkspaceRoundFact round,
    int? frontier,
    bool completed,
  ) {
    // Nothing will be flown after completion, so the latest round with a
    // score is finished too and its gaps are missing for good.
    final behind =
        frontier != null &&
        (round.ordinal < frontier || (completed && round.ordinal == frontier));
    final base = RoundProgressView.of(
      RoundStatus.open,
      scored: round.scored,
      total: round.total,
    ).state;
    final state = switch (base) {
      RoundProgressState.scored => ProgressTileState.scored,
      _ when round.total == 0 => ProgressTileState.notFlown,
      _ when behind => ProgressTileState.missing,
      RoundProgressState.inProgress => ProgressTileState.inProgress,
      _ => ProgressTileState.notFlown,
    };
    return ProgressTile(
      ordinal: round.ordinal,
      state: state,
      scored: round.scored,
      total: round.total,
    );
  }

  final ProgressHeadline headline;
  final List<ProgressTile> tiles;

  /// Set only while the current group is still being entered.
  final ProgressLag? lag;

  /// Finished rounds that lack scores, in round order. This is the one
  /// missing-scores rule: the needs-attention row and the completion dialog
  /// read it too.
  List<MissingRound> get missingRounds => [
    for (final tile in tiles)
      if (tile.state == ProgressTileState.missing)
        MissingRound(ordinal: tile.ordinal, missing: tile.missing),
  ];

  /// Scores missing across [missingRounds].
  int get missingTotal =>
      missingRounds.fold(0, (sum, round) => sum + round.missing);

  @override
  List<Object?> get props => [headline, tiles, lag];
}
