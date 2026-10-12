import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/pages/contest/workspace_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/services/workspace/workspace_control_target.dart';
import 'package:soar_score_contest/widgets/contest_shell.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'matrix_test_support.dart';

/// The fake server behind the next-step card tests: the matrix server plus
/// scores, a publication, and contest actions that change the contest.
class WorkspaceServer {
  WorkspaceServer({
    LifecycleState state = LifecycleState.running,
    AdminLock lock = AdminLock.unlocked,
    ScoringAccess access = ScoringAccess.closed,
    ContestConfigurationRevision? configuration,
    CurrentMatrix? matrix,
    this.scores,
    this.scoresStatus = 200,
  }) : contest = _contest(state, lock, access),
       inner = MatrixServer(configuration: configuration, matrix: matrix);

  Contest contest;
  final MatrixServer inner;
  ContestScores? scores;
  int scoresStatus;

  /// When set, the next action is answered with this status and message.
  int? rejectNext;
  String rejectMessage = 'The contest changed.';

  /// When set, actions wait for it, so a test can look at the card while one
  /// runs.
  Completer<void>? actionGate;

  /// The actions received, as `action` names.
  final List<String> actions = [];

  /// How many times the contest was read.
  int contestReads = 0;

  static Contest _contest(
    LifecycleState state,
    AdminLock lock,
    ScoringAccess access,
  ) {
    final base = matrixContest(state: state, lock: lock);
    return Contest(
      id: base.id,
      name: base.name,
      startDateTime: base.startDateTime,
      endDateTime: base.endDateTime,
      timezone: base.timezone,
      lifecycleState: state,
      scoringAccess: access,
      adminLock: lock,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      revision: 1,
    );
  }

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  http.Response _error(int status, String message) => _json({
    'error': {'code': 'rejected', 'message': message},
  }, status);

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    if (request.method == 'POST' && path.endsWith('/actions')) {
      await actionGate?.future;
      return _action(jsonDecode(request.body) as Map<String, dynamic>);
    }
    if (path.endsWith('/scores')) {
      final current = scores;
      return current == null || scoresStatus != 200
          ? _error(scoresStatus == 200 ? 404 : scoresStatus, 'No scores.')
          : _json(current.toJson());
    }
    if (path.endsWith('/publication')) {
      return _error(404, 'No publication.');
    }
    if (path.endsWith('/contests/$matrixContestId')) {
      contestReads++;
      return _json(contest.toJson());
    }
    return inner.handle(request);
  }

  http.Response _action(Map<String, dynamic> body) {
    final name = body['action'] as String;
    actions.add(name);
    final reject = rejectNext;
    if (reject != null) {
      rejectNext = null;
      return _error(reject, rejectMessage);
    }
    if (body['base_revision'] != contest.revision) {
      return _error(409, 'The contest was changed by someone else.');
    }
    final next = switch (name) {
      'openScoring' => contest.copyWithState(
        scoringAccess: ScoringAccess.open,
        updatedAt: DateTime.utc(2026, 10, 17, 15),
      ),
      'closeScoring' => contest.copyWithState(
        scoringAccess: ScoringAccess.closed,
        updatedAt: DateTime.utc(2026, 10, 17, 15),
      ),
      'lock' => contest.copyWithState(
        adminLock: AdminLock.locked,
        updatedAt: DateTime.utc(2026, 10, 17, 15),
      ),
      'unlock' => contest.copyWithState(
        adminLock: AdminLock.unlocked,
        updatedAt: DateTime.utc(2026, 10, 17, 15),
      ),
      _ => null,
    };
    if (next == null) {
      return _error(409, 'Not supported here.');
    }
    final json = next.toJson();
    json['revision'] = contest.revision + 1;
    contest = Contest.fromJson(json);
    return _json(contest.toJson());
  }
}

/// Pumps the workspace page for [server] inside a router that also has stubs
/// for the pages the card navigates to.
Future<void> pumpWorkspace(
  WidgetTester tester,
  WorkspaceServer server, {
  Size size = const Size(1200, 1600),
  double textScale = 1,
  DateTime Function()? clock,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final now = clock ?? () => DateTime.utc(2026, 10, 17, 16);
  final router = GoRouter(
    initialLocation: contestWorkspacePath(matrixContestId),
    routes: [
      GoRoute(
        path: contestWorkspacePath(matrixContestId),
        builder: (context, state) => Scaffold(
          body: ContestWorkspacePage(contestId: matrixContestId, clock: now),
        ),
      ),
      for (final entry in {
        contestConfigurationPath(matrixContestId): 'Configuration stub',
        contestMatrixPath(matrixContestId): 'Matrix stub',
        participantsPath: 'Participants stub',
      }.entries)
        GoRoute(
          path: entry.key,
          builder: (context, state) => Text(entry.value),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ApiClientInherited(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient(server.handle),
      ),
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The card's title.
String cardTitle(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('next-step-title'))).data!;

/// Pumps the real shell around the workspace for [server]: the status panel
/// above the page, plus a configuration stub to start from.
///
/// [location] is where the router starts; [disableAnimations] turns on
/// reduced motion.
Future<GoRouter> pumpShellWorkspace(
  WidgetTester tester,
  WorkspaceServer server, {
  String? location,
  bool disableAnimations = false,
  Size size = const Size(1000, 520),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: location ?? contestWorkspacePath(matrixContestId),
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            ContestShell(state: state, child: child),
        routes: [
          GoRoute(
            path: contestWorkspacePath(matrixContestId),
            builder: (context, state) => ContestWorkspacePage(
              contestId: matrixContestId,
              initialFocus: WorkspaceControlTarget.fromFragment(
                state.uri.fragment,
              ),
            ),
          ),
          GoRoute(
            path: contestConfigurationPath(matrixContestId),
            builder: (context, state) => const Text('Configuration stub'),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ApiClientInherited(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient(server.handle),
      ),
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
