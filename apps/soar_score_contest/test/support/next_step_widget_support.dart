import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/connectivity_provider.dart';
import 'package:soar_score_contest/services/connectivity/app_connectivity.dart';
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

  /// When not 404, reading the publication fails with this status.
  int publicationStatus = 404;

  /// The error code sent with a failed publication read.
  String publicationReadCode = 'rejected';

  /// The publication the server holds; set by a publish, or by a test to start
  /// published. While null, reading it is [publicationStatus].
  Map<String, Object?>? publication;

  /// When set, the next publish or visibility change is refused with this
  /// status and error code.
  int? publicationRefusal;
  String publicationRefusalCode = 'stale_source_revision';

  /// The delisting request the server holds, as JSON (null: none). A request
  /// made through the API is stored here as pending.
  Map<String, Object?>? delistRequest;

  /// When set, the next delisting request or withdrawal is refused with this
  /// status and error code.
  int? delistRefusal;
  String delistRefusalCode = 'publication_delisted';

  /// The reasons sent with delisting requests (null for none).
  final List<String?> delistReasons = [];

  /// How many withdrawals were received.
  int delistWithdrawals = 0;

  /// When not 200, reading the publication history fails with this status.
  int historyStatus = 200;

  /// The history the server answers with; while null it lists one automatic
  /// copy per projection revision of the publication, newest first, the first
  /// by the director.
  List<Map<String, Object?>>? history;

  /// The bodies of the publish requests received.
  final List<Map<String, dynamic>> publishes = [];

  /// The visibilities requested, as sent (`Public` or `Unlisted`).
  final List<String> visibilities = [];

  /// Starts the server with results hidden through [round] since [at].
  void startHidden({int round = 2, DateTime? at}) {
    contest = contest.copyWithState(
      hideResultsThroughRound: round,
      updatedAt: at ?? DateTime.utc(2026, 10, 17, 15),
    );
  }

  /// Starts the server with a published contest.
  void startPublished({String visibility = 'Unlisted'}) {
    publication = {
      'publication_id': 'p1',
      'visibility': visibility,
      'published_at': '2026-10-17T15:00:00.000Z',
      'current_projection': {
        'projection_revision': 1,
        'contest_revision': 1,
        'published_at': '2026-10-17T15:00:00.000Z',
      },
    };
  }

  /// When not 200, reading the configuration fails with this status.
  int configurationStatus = 200;

  /// When set, the next action is answered with this status and message.
  int? rejectNext;
  String rejectMessage = 'The contest changed.';

  /// When set, actions wait for it, so a test can look at the card while one
  /// runs.
  Completer<void>? actionGate;

  /// When not 200, reading the contest fails with this status.
  int contestStatus = 200;

  /// When true, every request fails like a lost connection.
  bool networkDown = false;

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

  http.Response _coded(int status, String code) => _json({
    'error': {'code': code, 'message': code},
  }, status);

  Future<http.Response> handle(http.Request request) async {
    if (networkDown) {
      throw http.ClientException('offline', request.url);
    }
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
    if (path.endsWith('/configuration') && configurationStatus != 200) {
      return _error(configurationStatus, 'Configuration lookup failed.');
    }
    if (path.endsWith('/publication/projections')) {
      if (historyStatus != 200) {
        return _coded(historyStatus, 'rejected');
      }
      final revision =
          (publication?['current_projection']
                  as Map<String, Object?>?)?['projection_revision']
              as int? ??
          0;
      return _json({
        'projections':
            history ??
            [
              for (var r = revision; r >= 1; r--)
                {
                  'id': '019c0000-0000-7000-8000-0000000000${(10 + r)}',
                  'projection_revision': r,
                  'contest_revision': 1,
                  'published_at': '2026-10-17T15:00:00.000Z',
                  'published_by': '019c0000-0000-7000-8000-000000000001',
                  'publisher_kind': r == 1 ? 'person' : 'system',
                },
            ],
      });
    }
    if (path.endsWith('/publication/delist-requests')) {
      final refusal = delistRefusal;
      if (refusal != null) {
        return _coded(refusal, delistRefusalCode);
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      delistReasons.add(body['reason'] as String?);
      final pending = delistRequest?['state'] == 'pending';
      delistRequest = pending
          ? delistRequest
          : _delist(reason: body['reason'] as String?);
      return _json(delistRequest!, pending ? 200 : 201);
    }
    if (path.endsWith('/publication/delist-requests/current')) {
      final current = delistRequest;
      if (request.method == 'DELETE') {
        final refusal = delistRefusal;
        if (refusal != null) {
          return _coded(refusal, delistRefusalCode);
        }
        if (current == null || current['state'] != 'pending') {
          return _coded(404, 'not_found');
        }
        delistWithdrawals++;
        delistRequest = {...current, 'state': 'withdrawn'};
        return _json(delistRequest!);
      }
      return current == null ? _coded(404, 'not_found') : _json(current);
    }
    if (path.endsWith('/publication/visibility')) {
      final refusal = publicationRefusal;
      if (refusal != null) {
        return _coded(refusal, publicationRefusalCode);
      }
      final visibility =
          (jsonDecode(request.body) as Map<String, dynamic>)['visibility']
              as String;
      visibilities.add(visibility);
      publication = {...?publication, 'visibility': visibility};
      return _json(publication!);
    }
    if (request.method == 'POST' && path.endsWith('/publication')) {
      final refusal = publicationRefusal;
      if (refusal != null) {
        return _coded(refusal, publicationRefusalCode);
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      publishes.add(body);
      final previous = publication;
      final revision =
          ((previous?['current_projection']
                      as Map<String, Object?>?)?['projection_revision']
                  as int? ??
              0) +
          1;
      publication = {
        'publication_id': 'p1',
        'visibility': previous?['visibility'] ?? 'Unlisted',
        'published_at': previous?['published_at'] ?? '2026-10-17T16:00:00.000Z',
        'current_projection': {
          'projection_revision': revision,
          'contest_revision': body['source_contest_revision'],
          'published_at': '2026-10-17T16:00:00.000Z',
        },
      };
      return _json(publication!, previous == null ? 201 : 200);
    }
    if (path.endsWith('/publication')) {
      final current = publication;
      return current != null
          ? _json(current)
          : _coded(publicationStatus, publicationReadCode);
    }
    if (path.endsWith('/contests/$matrixContestId')) {
      contestReads++;
      if (contestStatus != 200) {
        return _error(contestStatus, 'Contest lookup failed.');
      }
      return _json(contest.toJson());
    }
    return inner.handle(request);
  }

  /// A pending delisting request as the server sends it.
  static Map<String, Object?> _delist({String? reason}) => {
    'id': '019c0000-0000-7000-8000-0000000000d1',
    'publication_id': '019c0000-0000-7000-8000-000000000030',
    'requested_by': '019c0000-0000-7000-8000-000000000001',
    'trigger': 'owner_request',
    'reason': reason,
    'requested_at': '2026-10-18T09:00:00.000Z',
    'state': 'pending',
    'decided_by': null,
    'decided_at': null,
    'decision_note': null,
  };

  /// Starts the server with a pending delisting request.
  void startDelistPending() => delistRequest = _delist();

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
      'hideResults' when contest.lifecycleState == LifecycleState.running =>
        contest.copyWithState(
          hideResultsThroughRound: 2,
          updatedAt: DateTime.utc(2026, 10, 17, 15),
        ),
      'showResults' when contest.resultsHidden => contest.copyWithState(
        clearResultsHiding: true,
        updatedAt: DateTime.utc(2026, 10, 17, 15),
      ),
      'complete' when contest.lifecycleState == LifecycleState.running =>
        contest.copyWithState(
          lifecycleState: LifecycleState.completed,
          scoringAccess: ScoringAccess.closed,
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
  AppConnectivity? monitor,
  String contestId = matrixContestId,
  bool settle = true,
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
          body: ContestWorkspacePage(contestId: contestId, clock: now),
        ),
      ),
      for (final entry in {
        contestConfigurationPath(matrixContestId): 'Configuration stub',
        contestMatrixPath(matrixContestId): 'Matrix stub',
        contestScoringPath(matrixContestId): 'Scoring stub',
        contestParticipantsPath(matrixContestId): 'Participants stub',
        contestPublicationPath(matrixContestId): 'Publication stub',
      }.entries)
        GoRoute(
          path: entry.key,
          builder: (context, state) => Text(entry.value),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    _withMonitor(
      monitor,
      ApiClientInherited(
        client: ApiClient(
          baseUrl: Uri.parse('http://localhost'),
          httpClient: MockClient(server.handle),
        ),
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
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
  Size size = const Size(1000, 560),
  AppConnectivity? monitor,
  bool settle = true,
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
          GoRoute(
            path: homePath,
            builder: (context, state) => const Text('Home stub'),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    _withMonitor(
      monitor,
      ApiClientInherited(
        client: ApiClient(
          baseUrl: Uri.parse('http://localhost'),
          httpClient: MockClient(server.handle),
        ),
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: disableAnimations),
            child: child!,
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
  return router;
}

Widget _withMonitor(AppConnectivity? monitor, Widget child) => monitor == null
    ? child
    : AppConnectivityInherited(monitor: monitor, child: child);

/// [pumpWorkspace] after one frame only, so the loading state is on screen.
Future<void> pumpWorkspaceNoSettle(
  WidgetTester tester,
  WorkspaceServer server,
) => pumpWorkspace(tester, server, settle: false);

/// [pumpShellWorkspace] after one frame only.
Future<GoRouter> pumpShellWorkspaceNoSettle(
  WidgetTester tester,
  WorkspaceServer server, {
  bool disableAnimations = false,
}) => pumpShellWorkspace(
  tester,
  server,
  disableAnimations: disableAnimations,
  settle: false,
);
