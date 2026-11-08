import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/pages/contest/workspace_page.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/pilot_invitations.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/matrix_test_support.dart';

class _Source implements PilotInvitationSource {
  final sent = <List<Id>>[];
  final links = <String, String>{};

  @override
  Future<PilotInvitations> read(ApiClient client, Id contestId) async =>
      PilotInvitations(links: Map.of(links));

  @override
  Future<void> send(ApiClient client, Id contestId, List<Id> ids) async {
    sent.add(ids);
    for (final id in ids) {
      links[id.value] = 'https://x.test/${id.value}';
    }
  }
}

Future<void> _pump(WidgetTester tester, MatrixServer server) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
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
        home: Scaffold(body: ContestWorkspacePage(contestId: matrixContestId)),
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
}
