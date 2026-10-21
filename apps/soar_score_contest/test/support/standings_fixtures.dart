import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:soar_score_core/soar_score_core.dart';

import 'package:soar_score_contest/services/reports/reports_facts.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts.dart';

import 'matrix_test_support.dart';
import 'next_step_widget_support.dart';
import 'workspace_facts_support.dart';

final Id _revision = Id.parse('019c0000-0000-7000-8000-0000000000e1');
final DateTime _computed = DateTime.utc(2026, 10, 17, 18);

/// A stored standing of pilot [pilot] (1 to 4) as of round [asOf].
ParticipationStanding standing(
  int pilot, {
  required int asOf,
  required int place,
  required double overall,
  double? raw,
  List<int> dropped = const [],
  double penalty = 0,
  bool tied = false,
  bool preliminary = false,
}) => ParticipationStanding(
  id: Id.create(),
  contestId: contestId,
  contestParticipationId: participationId(pilot),
  asOfRound: asOf,
  place: place,
  isTied: tied,
  rawTotal: raw ?? overall,
  droppedRounds: dropped,
  penaltyTotal: penalty,
  overallScore: overall,
  isPreliminary: preliminary,
  configRevisionId: _revision,
  matrixRevisionId: _revision,
  calculationVersion: 'f5j-1',
  computedAt: _computed,
);

/// The selected flight of [pilot] in [round] with its [score]. The
/// [placeholder] is the score slot the flight came from, so Flight details can
/// find what was recorded.
FlightResult flight(
  int pilot,
  int round,
  double score, {
  required Id placeholder,
  double? landing = 50,
  bool selected = true,
}) => FlightResult(
  id: Id.create(),
  contestId: contestId,
  scorePlaceholderId: placeholder,
  officialScoreId: Id.create(),
  contestParticipationId: participationId(pilot),
  creditedRoundId: Id.parse(
    '019c0000-0000-7000-8000-0000000002${round.toString().padLeft(2, '0')}',
  ),
  outcome: score == 0 ? FlightOutcome.zero : FlightOutcome.scored,
  rawPoints: score,
  landingPoints: landing,
  groupScore: score,
  isSelected: selected,
  isPreliminary: false,
  configRevisionId: _revision,
  matrixRevisionId: _revision,
  calculationVersion: 'f5j-1',
  computedAt: _computed,
);

/// Scores for [matrix] with every slot official, carrying the recorded
/// components of a flight: 9:52 and 105 m.
ContestScores recordedScores(CurrentMatrix matrix, {int rounds = 2}) {
  final scored = {
    for (var r = 1; r <= rounds; r++)
      for (var p = 1; p <= 4; p++) (r, p): at(r * 10 + p),
  };
  final base = scoresFor(matrix, scored);
  return ContestScores(
    rounds: base.rounds,
    slots: [
      for (final slot in base.slots)
        ScoreSlot(
          placeholder: slot.placeholder,
          officialScore: slot.officialScore == null
              ? null
              : OfficialScore(
                  id: slot.officialScore!.id,
                  contestId: slot.officialScore!.contestId,
                  scorePlaceholderId: slot.officialScore!.scorePlaceholderId,
                  scoreAttemptId: slot.officialScore!.scoreAttemptId,
                  scoreRevision: 1,
                  components: const {'time_flown': 592, 'launch_height': 105},
                  setAt: slot.officialScore!.setAt,
                  setBy: slot.officialScore!.setBy,
                  reason: 'Entered by the director',
                ),
        ),
    ],
  );
}

/// The score slot of [pilot] in [round] of [scores].
Id placeholderOf(
  CurrentMatrix matrix,
  ContestScores scores,
  int pilot,
  int round,
) {
  final roundId = matrix.rounds.singleWhere((r) => r.ordinal == round).id;
  final assignment = matrix.assignments.singleWhere(
    (a) =>
        a.scheduledRoundId == roundId &&
        a.contestParticipationId == participationId(pilot),
  );
  return scores.slots
      .singleWhere((s) => s.placeholder.assignmentId == assignment.id)
      .placeholder
      .id;
}

/// The two-round contest the standings tests read:
///
/// | pilot | round 1 | round 2 | as of 2          |
/// | ----- | ------- | ------- | ---------------- |
/// | 1     | 900.0   | 500.0   | 900.0, 2 dropped |
/// | 2     | 800.0   | 950.0   | 1,750.0          |
/// | 3     | 700.0   | 700.0   | 1,400.0          |
/// | 4     | 600.0   | 650.0   | 1,250 less 50    |
class StandingsFixture {
  /// [reviewPilot] has the score of round 2 in review.
  StandingsFixture({
    bool preliminary = false,
    int? reviewPilot,
    bool round2Cancelled = false,
  }) : matrix = drawnMatrix(
         round2Status: round2Cancelled
             ? RoundStatus.cancelled
             : RoundStatus.open,
       ) {
    final recorded = recordedScores(matrix);
    scores = reviewPilot == null
        ? recorded
        : _inReview(matrix, recorded, reviewPilot, 2);
    Id slot(int pilot, int round) =>
        placeholderOf(matrix, scores, pilot, round);
    final round1 = {1: 900.0, 2: 800.0, 3: 700.0, 4: 600.0};
    final round2 = {1: 500.0, 2: 950.0, 3: 700.0, 4: 650.0};
    roundResults = {
      1: RoundResults(
        ordinal: 1,
        flights: [
          for (final e in round1.entries)
            RoundFlightResult(
              group: e.key <= 2 ? 1 : 2,
              result: flight(e.key, 1, e.value, placeholder: slot(e.key, 1)),
            ),
        ],
      ),
      2: RoundResults(
        ordinal: 2,
        flights: [
          for (final e in round2.entries)
            RoundFlightResult(
              group: e.key == 1 || e.key == 3 ? 1 : 2,
              result: flight(e.key, 2, e.value, placeholder: slot(e.key, 2)),
            ),
        ],
      ),
    };
    standings = {
      1: ContestResults(
        asOfRound: 1,
        standings: [
          standing(1, asOf: 1, place: 1, overall: 900),
          standing(2, asOf: 1, place: 2, overall: 800),
          standing(3, asOf: 1, place: 3, overall: 700),
          standing(4, asOf: 1, place: 4, overall: 600),
        ],
      ),
      2: ContestResults(
        asOfRound: 2,
        standings: [
          standing(
            2,
            asOf: 2,
            place: 1,
            overall: 1750,
            preliminary: preliminary,
          ),
          standing(
            3,
            asOf: 2,
            place: 2,
            overall: 1400,
            preliminary: preliminary,
          ),
          standing(
            4,
            asOf: 2,
            place: 3,
            overall: 1200,
            raw: 1250,
            penalty: 50,
            preliminary: preliminary,
          ),
          standing(
            1,
            asOf: 2,
            place: 4,
            overall: 900,
            raw: 1400,
            dropped: const [2],
            preliminary: preliminary,
          ),
        ],
      ),
    };
  }

  static ContestScores _inReview(
    CurrentMatrix matrix,
    ContestScores scores,
    int pilot,
    int round,
  ) {
    final target = placeholderOf(matrix, scores, pilot, round);
    return ContestScores(
      rounds: scores.rounds,
      slots: [
        for (final slot in scores.slots)
          slot.placeholder.id == target
              ? ScoreSlot(
                  placeholder: ScorePlaceholder(
                    id: slot.placeholder.id,
                    contestId: slot.placeholder.contestId,
                    contestParticipationId:
                        slot.placeholder.contestParticipationId,
                    assignmentId: slot.placeholder.assignmentId,
                    state: ScorePlaceholderState.inReview,
                  ),
                  officialScore: slot.officialScore,
                )
              : slot,
      ],
    );
  }

  final CurrentMatrix matrix;
  late final ContestScores scores;
  late final Map<int, RoundResults> roundResults;
  late final Map<int, ContestResults> standings;
}

/// The workspace fake server plus the results routes, serving a
/// [StandingsFixture] and recording what the report asked for.
class StandingsServer extends WorkspaceServer {
  StandingsServer(
    StandingsFixture fixture, {
    super.state,
    ContestScores? scores,
  }) : fixture = fixture,
       super(
         configuration: matrixConfiguration(),
         matrix: fixture.matrix,
         scores: scores ?? fixture.scores,
       );

  final StandingsFixture fixture;

  /// The results URLs requested, in order.
  final List<Uri> requests = [];

  /// When set, the results routes fail with this status.
  int? resultsFail;

  /// When set, the results routes wait for it.
  Completer<void>? resultsGate;

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  @override
  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    final isRound = path.contains('/results/rounds/');
    if (!path.endsWith('/results') && !isRound) {
      return super.handle(request);
    }
    if (networkDown) {
      throw http.ClientException('offline', request.url);
    }
    requests.add(request.url);
    await resultsGate?.future;
    if (resultsFail != null) {
      return _json({
        'error': {'code': 'failed', 'message': 'Results failed.'},
      }, resultsFail!);
    }
    if (isRound) {
      final round = int.parse(path.split('/').last);
      final results = fixture.roundResults[round];
      return results == null
          ? _json({
              'error': {'code': 'bad_request', 'message': 'No such round.'},
            }, 400)
          : _json(results.toJson());
    }
    final asOf = int.tryParse(request.url.queryParameters['asOfRound'] ?? '');
    final latest = fixture.standings.keys.fold(0, (a, b) => a > b ? a : b);
    final results = fixture.standings[asOf ?? latest];
    return results == null
        ? _json({
            'error': {'code': 'bad_request', 'message': 'No such round.'},
          }, 400)
        : _json(results.toJson());
  }
}

/// The reports facts of [fixture]'s contest. [core] sets contest options
/// (teams, numbers, decimals); [participations] replaces the pilots.
ReportsFacts factsOf(
  StandingsFixture fixture, {
  Map<String, Object?> core = const {},
  List<ContestParticipation>? participations,
  ContestScores? scores,
  LifecycleState state = LifecycleState.running,
}) {
  final data = workspaceData(
    state: state,
    matrix: fixture.matrix,
    core: core,
    participations: participations,
  );
  final read = scores ?? fixture.scores;
  return ReportsFacts.derive(
    data: data,
    scores: read,
    workspace: WorkspaceFacts.derive(data: data, scores: read),
  );
}
