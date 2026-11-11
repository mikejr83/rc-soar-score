import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/app_sync_provider.dart';
import 'package:soar_score_contest/services/sync/app_sync_state.dart';
import 'package:soar_score_contest/services/sync/sync_scope_summary.dart';
import 'package:soar_score_contest/services/workspace/shell_round_item.dart';
import 'package:soar_score_contest/widgets/shell_round_loader.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/configuration_fixtures.dart';
import '../support/fake_app_sync.dart';
import '../support/matrix_test_support.dart';
import '../support/workspace_facts_support.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  testWidgets('the shown round is not a link while it reloads', (tester) async {
    final matrix = drawnMatrix();
    final server = MatrixServer(
      configuration: configRevision(3),
      matrix: matrix,
    );
    Completer<void>? gate;
    final client = ApiClient(
      baseUrl: Uri.parse('http://localhost'),
      httpClient: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/scores')) {
          await gate?.future;
          return _json(scoresFor(matrix, {(1, 1): at(0)}).toJson());
        }
        if (path.endsWith('/landing-tables')) {
          return _json({'landing_tables': <Object>[]});
        }
        if (path.endsWith('/publication')) {
          return _json({
            'error': {'code': 'x', 'message': 'No publication.'},
          }, 404);
        }
        return server.handle(request);
      }),
    );
    final contest = matrixContest(state: LifecycleState.running);
    final seen = <(bool hasItem, bool refreshing)>[];

    Future<void> pump(String path) => tester.pumpWidget(
      ApiClientInherited(
        client: client,
        child: MaterialApp(
          home: ShellRoundLoader(
            contest: contest,
            path: path,
            builder: (context, item, refreshing) {
              seen.add((item != null, refreshing));
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    await pump('/a');
    await tester.pumpAndSettle();
    expect(seen.last, (true, false));

    // Another page of the same contest: the last value stays but is marked
    // as refreshing until the read completes.
    gate = Completer<void>();
    await pump('/b');
    await tester.pump();
    expect(seen.last, (true, true));

    gate.complete();
    await tester.pumpAndSettle();
    expect(seen.last, (true, false));
  });

  testWidgets('a slow read from before a sync cannot replace the newer one', (
    tester,
  ) async {
    final matrix = drawnMatrix();
    final server = MatrixServer(
      configuration: configRevision(3),
      matrix: matrix,
    );
    final gate = Completer<void>();
    var scoreReads = 0;
    final client = ApiClient(
      baseUrl: Uri.parse('http://localhost'),
      httpClient: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/scores')) {
          // The first read is slow and old (nothing scored); the one after
          // the sync is quick and new (a score arrived).
          if (++scoreReads == 1) {
            await gate.future;
            return _json(scoresFor(matrix, {}).toJson());
          }
          return _json(scoresFor(matrix, {(1, 1): at(0)}).toJson());
        }
        if (path.endsWith('/landing-tables')) {
          return _json({'landing_tables': <Object>[]});
        }
        if (path.endsWith('/publication')) {
          return _json({
            'error': {'code': 'x', 'message': 'No publication.'},
          }, 404);
        }
        return server.handle(request);
      }),
    );
    final contest = matrixContest(state: LifecycleState.running);
    final sync = FakeAppSync();
    ShellRoundItem? shown;

    await tester.pumpWidget(
      AppSyncInherited(
        sync: sync,
        child: ApiClientInherited(
          client: client,
          child: MaterialApp(
            home: ShellRoundLoader(
              contest: contest,
              path: '/a',
              builder: (context, item, refreshing) {
                shown = item;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    sync.state = AppSyncState(
      scopes: {ContestScopeKey(contest.id): SyncScopeSummary(dataRevision: 1)},
    );
    await tester.pumpAndSettle();
    expect(shown?.kind, ShellRoundKind.inProgress);

    gate.complete();
    await tester.pumpAndSettle();
    expect(shown?.kind, ShellRoundKind.inProgress);
  });
}
