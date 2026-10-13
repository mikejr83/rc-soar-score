import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/matrix/round_progress_view.dart';
import 'package:soar_score_contest/services/workspace/current_group_facts.dart';
import 'package:soar_score_contest/services/workspace/progress/missing_round.dart';
import 'package:soar_score_contest/services/workspace/progress/progress_headline.dart';
import 'package:soar_score_contest/services/workspace/progress/progress_summary.dart';
import 'package:soar_score_contest/services/workspace/progress/progress_tile.dart';
import 'package:soar_score_contest/services/workspace/workspace_round_fact.dart';
import 'package:soar_score_core/soar_score_core.dart';

WorkspaceRoundFact _round(
  int ordinal,
  int scored, {
  int total = 24,
  int groups = 4,
}) => WorkspaceRoundFact(
  ordinal: ordinal,
  groupCount: groups,
  scored: scored,
  total: total,
  state: RoundProgressView.of(
    RoundStatus.open,
    scored: scored,
    total: total,
  ).state,
);

/// Rounds from [scored] counts, 24 pilots each, in 4 groups.
List<WorkspaceRoundFact> _rounds(List<int> scored, {int total = 24}) => [
  for (var i = 0; i < scored.length; i++)
    _round(i + 1, scored[i], total: total),
];

ProgressSummary _derive(
  List<WorkspaceRoundFact> rounds, {
  bool seeded = false,
  int? intended,
  CurrentGroupFacts? frontierGroup,
  DateTime? latestScoreAt,
  int scoreCount = 0,
  bool completed = false,
  bool scoresAvailable = true,
}) => ProgressSummary.derive(
  rounds: rounds,
  scoresAvailable: scoresAvailable,
  seeded: seeded,
  intendedTotalRounds: intended,
  roundCount: rounds.length,
  groupCount: 4,
  groupSizeMin: 6,
  groupSizeMax: 6,
  matrixRevision: 2,
  frontierGroup: frontierGroup,
  latestScoreAt: latestScoreAt,
  scoreCount: scoreCount,
  completed: completed,
);

List<ProgressTileState> _states(ProgressSummary summary) => [
  for (final tile in summary.tiles) tile.state,
];

void main() {
  group('a running contest (frames 4a and 4b)', () {
    final groupB = CurrentGroupFacts(
      roundOrdinal: 3,
      groupNumber: 2,
      scored: 2,
      total: 6,
    );
    final summary = _derive(
      _rounds([23, 21, 13, 0, 0, 0, 0, 0]),
      frontierGroup: groupB,
      latestScoreAt: DateTime.utc(2026, 10, 17, 13, 31),
      scoreCount: 57,
    );

    test(
      'finished rounds with gaps are missing, the frontier is in progress',
      () {
        expect(_states(summary), [
          ProgressTileState.missing,
          ProgressTileState.missing,
          ProgressTileState.inProgress,
          ...List.filled(5, ProgressTileState.notFlown),
        ]);
        expect(summary.missingRounds, const [
          MissingRound(ordinal: 1, missing: 1),
          MissingRound(ordinal: 2, missing: 3),
        ]);
        expect(summary.missingTotal, 4);
      },
    );

    test('the headline names the current round and group', () {
      final headline = summary.headline;
      expect(headline.stage, ProgressStage.inProgress);
      expect((headline.currentRound, headline.totalRounds), (3, 8));
      expect((headline.currentGroup, headline.groupsInCurrentRound), (2, 4));
      expect(headline.latestScoreAt, DateTime.utc(2026, 10, 17, 13, 31));
    });

    test('the lag note counts the pilots of the group still to enter', () {
      expect(summary.lag, isNotNull);
      expect((summary.lag!.roundOrdinal, summary.lag!.groupNumber), (3, 2));
      expect(summary.lag!.pending, 4);
    });

    test('ten rounds give ten tiles', () {
      final ten = _derive(_rounds([24, 24, 23, 24, 13, 0, 0, 0, 0, 0]));
      expect(ten.tiles, hasLength(10));
      expect(ten.missingRounds, const [MissingRound(ordinal: 3, missing: 1)]);
      expect(ten.headline.currentRound, 5);
    });
  });

  group('the lag note', () {
    test('is absent when the group is complete', () {
      final summary = _derive(
        _rounds([24, 13]),
        frontierGroup: CurrentGroupFacts(
          roundOrdinal: 2,
          groupNumber: 2,
          scored: 6,
          total: 6,
        ),
      );
      expect(summary.lag, isNull);
    });

    test('is absent when the frontier round is complete', () {
      final summary = _derive(
        _rounds([24, 24, 0]),
        frontierGroup: CurrentGroupFacts(
          roundOrdinal: 2,
          groupNumber: 4,
          scored: 5,
          total: 6,
        ),
      );
      expect(summary.tiles[1].state, ProgressTileState.scored);
      expect(summary.lag, isNull);
    });

    test('is absent for a group that is not in the frontier round', () {
      final summary = _derive(
        _rounds([24, 13]),
        frontierGroup: CurrentGroupFacts(
          roundOrdinal: 1,
          groupNumber: 1,
          scored: 1,
          total: 6,
        ),
      );
      expect(summary.lag, isNull);
      expect(summary.headline.currentGroup, isNull);
    });

    test('is absent once the contest is completed', () {
      final summary = _derive(
        _rounds([24, 23]),
        completed: true,
        frontierGroup: CurrentGroupFacts(
          roundOrdinal: 2,
          groupNumber: 4,
          scored: 5,
          total: 6,
        ),
      );
      expect(summary.lag, isNull);
    });
  });

  group('rounds that were never flown', () {
    test('a round behind the frontier with no scores is missing', () {
      final summary = _derive(_rounds([24, 0, 13]));
      expect(summary.tiles[1].state, ProgressTileState.missing);
      expect(summary.missingRounds, const [
        MissingRound(ordinal: 2, missing: 24),
      ]);
    });

    test('a round of retired pilots only is not missing', () {
      final summary = _derive([
        _round(1, 24),
        _round(2, 0, total: 0),
        _round(3, 13),
      ]);
      expect(summary.tiles[1].state, ProgressTileState.notFlown);
      expect(summary.missingRounds, isEmpty);
    });
  });

  group('a seeded contest (frame 4c)', () {
    test('rounds past the drawn set are not drawn', () {
      final summary = _derive(
        _rounds([24, 24, 24, 24]),
        seeded: true,
        intended: 8,
      );
      expect(_states(summary), [
        ...List.filled(4, ProgressTileState.scored),
        ...List.filled(4, ProgressTileState.notDrawn),
      ]);
      expect(
        [for (final t in summary.tiles) t.ordinal],
        [
          1, 2, 3, 4, 5, 6, 7, 8, //
        ],
      );
      expect(summary.headline.currentRound, 4);
      expect(summary.headline.totalRounds, 8);
      expect(summary.missingRounds, isEmpty);
    });

    test('a standard draw ignores the intended total', () {
      final summary = _derive(_rounds([24, 24]), intended: 8);
      expect(summary.tiles, hasLength(2));
      expect(summary.headline.totalRounds, 2);
    });
  });

  group('nothing scored yet (frame 4d)', () {
    final summary = _derive(_rounds([0, 0, 0, 0, 0, 0, 0, 0]));

    test('the headline describes the matrix', () {
      final headline = summary.headline;
      expect(headline.stage, ProgressStage.noScores);
      expect((headline.roundCount, headline.groupCount), (8, 4));
      expect((headline.groupSizeMin, headline.groupSizeMax), (6, 6));
      expect(headline.matrixRevision, 2);
    });

    test('every round is not flown and nothing is missing', () {
      expect(_states(summary), everyElement(ProgressTileState.notFlown));
      expect(summary.missingRounds, isEmpty);
      expect(summary.lag, isNull);
    });
  });

  group('a completed contest', () {
    test('the headline reports the rounds flown and the scores', () {
      final summary = _derive(
        _rounds(List.filled(8, 24)),
        completed: true,
        scoreCount: 192,
      );
      final headline = summary.headline;
      expect(headline.stage, ProgressStage.finished);
      expect(headline.allRoundsFlown, isTrue);
      expect((headline.roundsFlown, headline.scoreCount), (8, 192));
    });

    test(
      'gaps in the last scored round are missing, later rounds are not flown',
      () {
        final summary = _derive(
          _rounds([24, 24, 22, 0]),
          completed: true,
          scoreCount: 70,
        );
        expect(summary.headline.allRoundsFlown, isFalse);
        expect(summary.headline.roundsFlown, 3);
        expect(summary.missingRounds, const [
          MissingRound(ordinal: 3, missing: 2),
        ]);
      },
    );

    test('a completed contest without scores reads as no scores', () {
      final summary = _derive(_rounds([0, 0]), completed: true);
      expect(summary.headline.stage, ProgressStage.noScores);
    });
  });

  test('unavailable scores give no tiles', () {
    final summary = _derive(const [], scoresAvailable: false);
    expect(summary.headline.stage, ProgressStage.scoresUnavailable);
    expect(summary.tiles, isEmpty);
    expect(summary.missingRounds, isEmpty);
  });
}
