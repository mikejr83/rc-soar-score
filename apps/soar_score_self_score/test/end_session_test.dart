import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_self_score/models/guest_session.dart';
import 'package:soar_score_self_score/session/end_session.dart';
import 'package:soar_score_self_score/session/guest_session_store.dart';

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
}
