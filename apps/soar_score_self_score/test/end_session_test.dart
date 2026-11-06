import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_self_score/api_client_provider.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/models/guest_session.dart';
import 'package:soar_score_self_score/session/end_session.dart';
import 'package:soar_score_self_score/session/guest_session_scope.dart';
import 'package:soar_score_self_score/session/guest_session_store.dart';
import 'package:soar_score_self_score/widgets/end_session_button.dart';

MemoryGuestSessionStore _signedIn() => MemoryGuestSessionStore()
  ..write(
    GuestSession(
      contestId: 'c',
      contestName: 'C',
      pilotId: 'p',
      pilotName: 'P',
      expiresAt: DateTime.utc(2099),
    ),
  );

ApiClient _client(Future<http.Response> Function(http.Request) respond) =>
    ApiClient(
      baseUrl: Uri.parse('http://localhost:8080'),
      httpClient: MockClient(respond),
    );

void main() {
  test('ending the session asks the server and clears the device', () async {
    final store = _signedIn();
    final paths = <String>[];
    await endGuestSession(
      _client((request) async {
        paths.add('${request.method} ${request.url.path}');
        return http.Response('', 204);
      }),
      store,
    );
    expect(paths, ['POST /api/v1/self-scoring/session/end']);
    expect(store.read(), isNull);
  });

  test('a failed server call still clears the device', () async {
    for (final respond in <Future<http.Response> Function(http.Request)>[
      (_) async => http.Response('', 500),
      (_) async => throw http.ClientException('offline'),
    ]) {
      final store = _signedIn();
      await endGuestSession(_client(respond), store);
      expect(store.read(), isNull);
    }
  });

  testWidgets('the button ends the session and returns to start', (
    tester,
  ) async {
    final store = _signedIn();
    var asked = false;
    final router = GoRouter(
      initialLocation: '/page',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('start page')),
        GoRoute(
          path: '/page',
          builder: (_, _) =>
              const Scaffold(body: Center(child: EndSessionButton())),
        ),
      ],
    );
    await tester.pumpWidget(
      ApiClientInherited(
        client: _client((_) async {
          asked = true;
          throw http.ClientException('offline');
        }),
        child: GuestSessionScope(
          store: store,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('End session'));
    await tester.pumpAndSettle();
    expect(asked, isTrue);
    expect(store.read(), isNull);
    expect(find.text('start page'), findsOneWidget);
  });
}
