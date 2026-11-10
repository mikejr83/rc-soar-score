import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/app_sync_provider.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/pages/contest/workspace_page.dart';
import 'package:soar_score_contest/services/sync/app_sync_state.dart';
import 'package:soar_score_contest/services/sync/sync_scope_summary.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/fake_app_sync.dart';
import '../support/matrix_test_support.dart';

AppSyncState _syncedAt(Id contest, DateTime at) => AppSyncState(
  scopes: {ContestScopeKey(contest): SyncScopeSummary(lastSyncedAt: at)},
);

void main() {
  testWidgets('a sync of the contest reads the workspace facts again', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final server = MatrixServer(configuration: matrixConfiguration());
    var scoreReads = 0;
    final sync = FakeAppSync();
    await tester.pumpWidget(
      AppSyncInherited(
        sync: sync,
        child: ApiClientInherited(
          client: ApiClient(
            baseUrl: Uri.parse('http://localhost'),
            httpClient: MockClient((request) async {
              final path = request.url.path;
              if (path.endsWith('/scores')) {
                scoreReads++;
                return http.Response('{}', 404);
              }
              if (path.endsWith('/publication')) {
                return http.Response('{}', 404);
              }
              return server.handle(request);
            }),
          ),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ContestWorkspacePage(contestId: matrixContestId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = scoreReads;
    expect(before, greaterThan(0));

    // Another scope syncing is not news to this page.
    sync.state = _syncedAt(Id.create(), DateTime.utc(2026, 11, 10));
    await tester.pumpAndSettle();
    expect(scoreReads, before);

    sync.state = _syncedAt(contestId, DateTime.utc(2026, 11, 10));
    await tester.pumpAndSettle();
    expect(scoreReads, greaterThan(before));
  });
}
