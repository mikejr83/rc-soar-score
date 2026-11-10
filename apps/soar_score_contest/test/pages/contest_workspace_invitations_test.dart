import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/connectivity_provider.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/app_sync_provider.dart';
import 'package:soar_score_contest/pages/contest/workspace_page.dart';
import 'package:soar_score_contest/services/sync/app_sync_state.dart';
import 'package:soar_score_contest/services/sync/sync_scope_summary.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/pilot_invitations.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/fake_app_connectivity.dart';
import '../support/fake_app_sync.dart';
import '../support/matrix_test_support.dart';

class _Source implements PilotInvitationSource {
  _Source({this.failSend = false, this.failReadAfterSend = false});

  bool synchronized = true;

  final bool failSend;
  final bool failReadAfterSend;
  final sent = <List<Id>>[];
  final links = <String, String>{};

  @override
  Future<PilotInvitations> read(ApiClient client, Id contestId) async {
    if (failReadAfterSend && sent.isNotEmpty) {
      return const PilotInvitations(loadFailed: true);
    }
    return PilotInvitations(links: Map.of(links), synchronized: synchronized);
  }

  @override
  Future<void> send(ApiClient client, Id contestId, List<Id> ids) async {
    if (failSend) throw StateError('no');
    sent.add(ids);
    for (final id in ids) {
      links[id.value] = 'https://x.test/${id.value}';
    }
  }
}

Future<void> _pump(
  WidgetTester tester,
  MatrixServer server, {
  FakeAppConnectivity? connectivity,
  FakeAppSync? sync,
}) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Widget app(Widget child) {
    final synced = sync == null
        ? child
        : AppSyncInherited(sync: sync, child: child);
    return connectivity == null
        ? synced
        : AppConnectivityInherited(monitor: connectivity, child: synced);
  }

  await tester.pumpWidget(
    app(
      ApiClientInherited(
        client: ApiClient(
          baseUrl: Uri.parse('http://localhost'),
          httpClient: MockClient((request) async {
            final path = request.url.path;
            if (path.endsWith('/scores') || path.endsWith('/publication')) {
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
}

void main() {
  late PilotInvitationSource original;
  setUp(() => original = PilotInvitationSources.current);
  tearDown(() => PilotInvitationSources.current = original);

  testWidgets('the invitations card sits under the setup checklist and sends', (
    tester,
  ) async {
    final source = _Source();
    PilotInvitationSources.current = source;
    await _pump(tester, MatrixServer(configuration: matrixConfiguration()));

    final checklist = tester.getTopLeft(
      find.byKey(const ValueKey('setup-checklist-card')),
    );
    final card = tester.getTopLeft(
      find.byKey(const ValueKey('workspace-invitations')),
    );
    expect(card.dy, greaterThan(checklist.dy));
    expect(card.dx, checklist.dx);
    expect(
      find.textContaining('0 of 4 pilots have a QR code.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('workspace-invitations-send')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nobody is emailed'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pumpAndSettle();

    expect(source.sent.single, hasLength(4));
    expect(
      find.text('4 invitations created. Nobody was emailed.'),
      findsOneWidget,
    );
    expect(find.textContaining('All 4 pilots have a QR code'), findsOneWidget);
  });

  testWidgets('a sync of the contest updates the card without leaving', (
    tester,
  ) async {
    final source = _Source()..synchronized = false;
    PilotInvitationSources.current = source;
    final sync = FakeAppSync();
    await _pump(
      tester,
      MatrixServer(configuration: matrixConfiguration()),
      sync: sync,
    );
    expect(find.textContaining('hasn’t synchronized'), findsOneWidget);

    // The sync puts the contest on the server.
    source.synchronized = true;
    sync.state = AppSyncState(
      scopes: {
        ContestScopeKey(contestId): SyncScopeSummary(
          lastSyncedAt: DateTime.utc(2026, 11, 10),
        ),
      },
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('hasn’t synchronized'), findsNothing);
    expect(
      find.textContaining('0 of 4 pilots have a QR code.'),
      findsOneWidget,
    );
  });

  testWidgets('a running contest still offers the card', (tester) async {
    PilotInvitationSources.current = _Source();
    await _pump(
      tester,
      MatrixServer(
        contest: matrixContest(state: LifecycleState.running),
        configuration: matrixConfiguration(),
        matrix: drawnMatrix(),
      ),
    );

    expect(find.byKey(const ValueKey('workspace-invitations')), findsOneWidget);
  });

  Future<void> sendAll(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('workspace-invitations-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pumpAndSettle();
  }

  testWidgets('a failed send says nothing was sent and issues nothing', (
    tester,
  ) async {
    final source = _Source(failSend: true);
    PilotInvitationSources.current = source;
    await _pump(tester, MatrixServer(configuration: matrixConfiguration()));

    await sendAll(tester);

    expect(source.sent, isEmpty);
    expect(
      find.text(
        'The invitations could not be created. Nothing was sent. Try again.',
      ),
      findsOneWidget,
    );
    // Still offered, for a retry.
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('workspace-invitations-send')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('a send whose read-back fails reports that it worked', (
    tester,
  ) async {
    final source = _Source(failReadAfterSend: true);
    PilotInvitationSources.current = source;
    await _pump(tester, MatrixServer(configuration: matrixConfiguration()));

    await sendAll(tester);

    expect(source.sent, hasLength(1));
    expect(
      find.textContaining('were created, but could not be loaded'),
      findsOneWidget,
    );
  });

  testWidgets('going offline turns sending off and sends nothing', (
    tester,
  ) async {
    final source = _Source();
    PilotInvitationSources.current = source;
    final connectivity = FakeAppConnectivity();
    await _pump(
      tester,
      MatrixServer(configuration: matrixConfiguration()),
      connectivity: connectivity,
    );

    connectivity
      ..internetStatus = ConnectivityStatus.unavailable
      ..notifyListeners();
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('workspace-invitations-send')),
          )
          .onPressed,
      isNull,
    );
    expect(
      find.text('You’re offline, so invitations can’t be sent now.'),
      findsOneWidget,
    );
    expect(source.sent, isEmpty);
  });

  testWidgets('an unreachable server turns sending off with its own reason', (
    tester,
  ) async {
    final source = _Source();
    PilotInvitationSources.current = source;
    final connectivity = FakeAppConnectivity();
    await _pump(
      tester,
      MatrixServer(configuration: matrixConfiguration()),
      connectivity: connectivity,
    );

    // The internet is up, the server is not.
    connectivity
      ..apiStatus = ConnectivityStatus.unavailable
      ..notifyListeners();
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('workspace-invitations-send')),
          )
          .onPressed,
      isNull,
    );
    expect(
      find.text(
        'The server can’t be reached, so invitations can’t be sent now.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a connection lost while confirming sends nothing', (
    tester,
  ) async {
    final source = _Source();
    PilotInvitationSources.current = source;
    final connectivity = FakeAppConnectivity();
    await _pump(
      tester,
      MatrixServer(configuration: matrixConfiguration()),
      connectivity: connectivity,
    );

    await tester.tap(find.byKey(const ValueKey('workspace-invitations-send')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cards-send-dialog')), findsOneWidget);
    // The connection drops while the director decides.
    connectivity
      ..internetStatus = ConnectivityStatus.unavailable
      ..notifyListeners();
    await tester.tap(find.byKey(const ValueKey('cards-send-confirm')));
    await tester.pumpAndSettle();

    expect(source.sent, isEmpty);
    expect(
      find.text('You’re offline, so invitations can’t be sent now.'),
      findsWidgets,
    );
  });
}
