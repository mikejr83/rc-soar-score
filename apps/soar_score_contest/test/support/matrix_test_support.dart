import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/collapsible_areas_provider.dart';
import 'package:soar_score_contest/contest_draft_provider.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/services/collapsible_areas/collapsible_areas_controller.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft_store.dart';
import 'package:soar_score_contest/pages/contest/matrix_page.dart';
import 'package:soar_score_contest/services/matrix/matrix_rounds_plan.dart';
import 'package:soar_score_core/soar_score_core.dart';

const String matrixContestId = '019c0000-0000-7000-8000-000000000017';
final DateTime _created = DateTime.utc(2026, 9);
final Id contestId = Id.parse(matrixContestId);
final Id _revisionId = Id.parse('019c0000-0000-7000-8000-0000000000e1');
final Id _actor = Id.parse('019c0000-0000-7000-8000-0000000000b1');

Id _id(String kind, int n) =>
    Id.parse('019c0000-0000-7000-8000-$kind${n.toString().padLeft(8, '0')}');

/// The participation id of pilot [n] (1 to 4).
Id participationId(int n) => _id('0001', n);

Contest matrixContest({
  LifecycleState state = LifecycleState.configuring,
  AdminLock lock = AdminLock.unlocked,
}) => Contest(
  id: contestId,
  name: 'Gator Cup F5J',
  startDateTime: DateTime.utc(2026, 10, 17, 14),
  endDateTime: DateTime.utc(2026, 10, 18, 14),
  timezone: 'America/Denver',
  lifecycleState: state,
  adminLock: lock,
  createdAt: _created,
  updatedAt: _created,
);

ContestConfigurationRevision matrixConfiguration([
  Map<String, Object?> core = const {},
]) => ContestConfigurationRevision(
  id: Id.parse('019c0000-0000-7000-8000-0000000000a1'),
  contestId: contestId,
  revisionNumber: 14,
  disciplineProfileId: Id.parse('019c0000-0000-7000-8000-0000000000d1'),
  config: ContestConfig(core: core, discipline: const {}),
  createdBy: _actor,
  createdAt: _created,
);

const _names = ['Ann Lee', 'Bo Ray', 'Cy Fox', 'Di Park'];

/// Four scoring pilots (numbered when [numbered]) and one official.
///
/// [retired] maps a pilot (1 to 4) to the round the pilot retired at.
List<ContestParticipation> matrixParticipations({
  bool numbered = false,
  Map<int, int> retired = const {},
  int revision = 0,
}) => [
  for (var n = 1; n <= 5; n++)
    ContestParticipation(
      id: _id('0001', n),
      contestId: contestId,
      participantProfileId: _id('0005', n),
      roleId: Id.parse('019c0000-0000-7000-8000-0000000000c1'),
      roleName: n <= 4 ? 'Pilot' : 'Timer',
      roleType: n <= 4 ? RoleType.pilot : RoleType.nonFlier,
      participantNumber: numbered && n <= 4 ? n : null,
      scoringUuid: ScoringUuid.parse('0000000$n-0000-4000-8000-000000000000'),
      retiredAtRound: retired[n],
      revision: revision,
    ),
];

List<ParticipantProfile> matrixProfiles() => [
  for (var n = 1; n <= 5; n++)
    ParticipantProfile(
      id: _id('0005', n),
      ownerAccountId: _actor,
      firstName: n <= 4 ? _names[n - 1].split(' ').first : 'Tim',
      lastName: n <= 4 ? _names[n - 1].split(' ').last : 'Keeper',
      createdAt: _created,
      updatedAt: _created,
    ),
];

/// Two teams: pilots 1 and 3 fly for the Gators, 2 and 4 for the Hawks.
List<Team> matrixTeams() => [
  Team(id: _id('0006', 1), contestId: contestId, name: 'Flying Gators'),
  Team(id: _id('0006', 2), contestId: contestId, name: 'Harbor Hawks'),
];

List<TeamMembership> matrixMemberships() => [
  for (var n = 1; n <= 4; n++)
    TeamMembership(
      id: _id('0007', n),
      teamId: _id('0006', n.isOdd ? 1 : 2),
      contestParticipationId: _id('0001', n),
      contestId: contestId,
    ),
];

/// Four pilots, two rounds, two groups: round 1 is {1,2} {3,4}; round 2 is
/// {1,3} {2,4}. Pilots 1 and 4 never meet.
///
/// [scored] gives the number of scored flights of round 1 and round 2; when
/// null the server sends no progress. [round2Status] sets the status of
/// round 2.
CurrentMatrix drawnMatrix({
  bool lanes = false,
  Map<String, Object?>? config,
  (int, int)? scored,
  RoundStatus round2Status = RoundStatus.open,
}) {
  final rounds = [
    for (var r = 1; r <= 2; r++)
      Round(
        id: _id('0002', r),
        contestId: contestId,
        matrixRevisionId: _revisionId,
        ordinal: r,
        groupCount: 2,
        status: r == 2 ? round2Status : RoundStatus.open,
      ),
  ];
  final groups = [
    for (var r = 1; r <= 2; r++)
      for (var g = 1; g <= 2; g++)
        RoundGroup(
          id: _id('0003', r * 10 + g),
          contestId: contestId,
          roundId: _id('0002', r),
          groupNumber: g,
        ),
  ];
  MatrixAssignment assignment(int round, int group, int pilot, int lane) =>
      MatrixAssignment(
        id: _id('0004', round * 100 + pilot),
        contestId: contestId,
        matrixRevisionId: _revisionId,
        contestParticipationId: _id('0001', pilot),
        scheduledRoundId: _id('0002', round),
        creditedRoundId: _id('0002', round),
        group: group,
        lane: lanes ? lane : null,
        assignmentType: AssignmentType.original,
        actorId: _actor,
        createdAt: _created,
      );
  return CurrentMatrix(
    revision: MatrixRevision(
      id: _revisionId,
      contestId: contestId,
      revisionNumber: 1,
      firstRound: 1,
      lastRound: 2,
      drawMode: DrawMode.standardManOnMan,
      randomSeed: 1849302217,
      algorithmVersion: 'optimized-1',
      drawConfig: config ?? const {},
      seedingSnapshot: const {},
      fairnessSummary: const {
        'fairness_score': 92.0,
        'unmet_opponent_count': 2,
        'max_duplicate_matchups': 1,
        'mean_absolute_deviation': 0.44,
        'matchup_histogram': {'0': 2, '1': 4},
      },
      createdBy: _actor,
      createdAt: DateTime.utc(2026, 10, 7, 14, 32),
    ),
    rounds: rounds,
    groups: groups,
    assignments: [
      assignment(1, 1, 1, 2),
      assignment(1, 1, 2, 1),
      assignment(1, 2, 3, 1),
      assignment(1, 2, 4, 2),
      assignment(2, 1, 1, 1),
      assignment(2, 1, 3, 2),
      assignment(2, 2, 2, 1),
      assignment(2, 2, 4, 2),
    ],
    progress: scored == null
        ? const []
        : [
            RoundProgress(
              roundId: _id('0002', 1),
              ordinal: 1,
              scored: scored.$1,
              total: 4,
            ),
            RoundProgress(
              roundId: _id('0002', 2),
              ordinal: 2,
              scored: scored.$2,
              total: 4,
            ),
          ],
  );
}

/// A fake server for the matrix page. [drawStatus] other than 200 answers
/// the draw with that status and [drawError]; [offline] makes every request
/// fail like a lost connection.
class MatrixServer {
  MatrixServer({
    Contest? contest,
    this.configuration,
    this.matrix,
    this.drawStatus = 200,
    this.drawError = 'The draw was rejected.',
    this.offline = false,
  }) : contest = contest ?? matrixContest();

  Contest contest;
  final ContestConfigurationRevision? configuration;
  CurrentMatrix? matrix;
  int drawStatus;
  String drawError;
  bool offline;

  /// The bodies of the draws received.
  final List<Map<String, dynamic>> draws = [];

  /// The bodies of the redraws (and round additions) received. A redraw is
  /// answered 201 with the matrix as it stands, unless [redrawStatus] says
  /// otherwise (then with [redrawCode] and [redrawError]).
  final List<Map<String, dynamic>> redraws = [];
  int redrawStatus = 201;
  String redrawCode = 'rounds_have_scores';
  String redrawError = 'round 1 already has scores';

  /// While set, a draw waits here instead of answering, reporting
  /// [drawPercent] to anyone who asks; completing it lets the draw finish.
  /// Cancelling the draw answers it 409 `draw_cancelled`.
  Completer<void>? holdDraw;
  int drawPercent = 40;

  /// How often the draw was asked for its progress, and cancelled.
  int statusRequests = 0;
  int cancelRequests = 0;

  /// Answers every cancel with this status when not 200.
  int cancelStatus = 200;
  Completer<void>? _cancelled;

  /// The round each pilot (1 to 4) retired at.
  final Map<int, int> retirements = {};

  /// The participation updates received, as `{pilot, body}`.
  final List<Map<String, dynamic>> participationUpdates = [];

  /// Answers every participation update with this status when not 200.
  int participationStatus = 200;

  /// A notice sent with every successful participation update.
  String? participationWarning;
  int _participationRevision = 0;

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  Future<http.Response> handle(http.Request request) async {
    if (offline) {
      throw http.ClientException('offline', request.url);
    }
    final path = request.url.path;
    final status = RegExp(r'/matrix/draws/([^/]+)$').firstMatch(path);
    if (status != null) {
      final id = status.group(1)!;
      final running = holdDraw != null && !holdDraw!.isCompleted;
      if (request.method == 'DELETE') {
        cancelRequests++;
        if (cancelStatus != 200) {
          return _json({
            'error': {'code': 'unavailable', 'message': 'try later'},
          }, cancelStatus);
        }
        if (!running) {
          return _json({
            'error': {'code': 'not_found', 'message': 'no such draw'},
          }, 404);
        }
        _cancelled?.complete();
      } else {
        statusRequests++;
        if (!running) {
          return _json({
            'error': {'code': 'not_found', 'message': 'no such draw'},
          }, 404);
        }
      }
      return _json({
        'id': id,
        'state': request.method == 'DELETE' ? 'cancelled' : 'running',
        'percent': drawPercent,
        'seed': 2,
        'seed_count': 3,
      });
    }
    if (request.method == 'POST' && path.endsWith('/matrix/redraws')) {
      redraws.add(jsonDecode(request.body) as Map<String, dynamic>);
      if (redrawStatus != 201) {
        return _json({
          'error': {'code': redrawCode, 'message': redrawError},
        }, redrawStatus);
      }
      return _json((matrix ?? CurrentMatrix()).toJson(), 201);
    }
    if (request.method == 'POST' && path.endsWith('/matrix/draws')) {
      draws.add(jsonDecode(request.body) as Map<String, dynamic>);
      final hold = holdDraw;
      if (hold != null) {
        _cancelled = Completer<void>();
        await Future.any([hold.future, _cancelled!.future]);
        if (_cancelled!.isCompleted) {
          return _json({
            'error': {
              'code': 'draw_cancelled',
              'message': 'the draw was cancelled; nothing was changed',
            },
          }, 409);
        }
      }
      if (drawStatus != 200) {
        return _json({
          'error': {'code': 'rejected', 'message': drawError},
        }, drawStatus);
      }
      matrix = drawnMatrix();
      return _json(matrix!.toJson());
    }
    if (path.endsWith('/configuration')) {
      return configuration == null
          ? _json({
              'error': {'code': 'not_found', 'message': 'none'},
            }, 404)
          : _json((configuration ?? matrixConfiguration()).toJson());
    }
    if (request.method == 'PUT' && path.contains('/participations/')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final id = Id.parse(path.split('/').last);
      final pilot = [
        for (var n = 1; n <= 5; n++)
          if (matrixParticipations()[n - 1].id == id) n,
      ].single;
      participationUpdates.add({'pilot': pilot, 'body': body});
      if (participationStatus != 200) {
        return _json({
          'error': {'code': 'rejected', 'message': 'The change was rejected.'},
        }, participationStatus);
      }
      final round = body['retired_at_round'] as int?;
      if (round == null) {
        retirements.remove(pilot);
      } else {
        retirements[pilot] = round;
      }
      _participationRevision++;
      return _json({
        ...matrixParticipations(
          retired: retirements,
          revision: _participationRevision,
        )[pilot - 1].toJson(),
        'recalculation_warning': participationWarning,
      });
    }
    if (path.endsWith('/participations')) {
      return _json({
        'participations': [
          for (final p in matrixParticipations(
            numbered: matrix != null,
            retired: retirements,
            revision: _participationRevision,
          ))
            p.toJson(),
        ],
      });
    }
    if (path.endsWith('/participants')) {
      return _json({
        'participants': [for (final p in matrixProfiles()) p.toJson()],
      });
    }
    if (path.endsWith('/team-memberships')) {
      return _json({
        'team_memberships': [for (final m in matrixMemberships()) m.toJson()],
      });
    }
    if (path.endsWith('/teams')) {
      return _json({
        'teams': [for (final t in matrixTeams()) t.toJson()],
      });
    }
    if (path.endsWith('/matrix')) {
      return _json((matrix ?? CurrentMatrix()).toJson());
    }
    return _json(contest.toJson());
  }
}

/// Pumps [MatrixPage] against [server] in a window of [size].
Future<void> pumpMatrixPage(
  WidgetTester tester,
  MatrixServer server, {
  Size size = const Size(1280, 1100),
  ContestDraftStore? drafts,
  CollapsibleAreasController? areas,
  MatrixIntent? intent,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Widget page = MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MatrixPage(contestId: matrixContestId, initialIntent: intent),
    ),
  );
  if (areas != null) {
    page = CollapsibleAreasInherited(controller: areas, child: page);
  }
  await tester.pumpWidget(
    ApiClientInherited(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient(server.handle),
      ),
      child: ContestDraftInherited(
        store: drafts ?? ContestDraftStore(),
        child: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
