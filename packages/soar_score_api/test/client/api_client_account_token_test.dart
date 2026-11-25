import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:test/test.dart';

void main() {
  late List<http.Request> seen;

  ApiClient clientWith({TokenProvider? tokens, TokenProvider? accountTokens}) {
    seen = [];
    final client = ApiClient(
      baseUrl: Uri.parse('http://localhost:8085'),
      httpClient: MockClient((request) async {
        seen.add(request);
        return http.Response(
          '{"participations": []}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
      tokenProvider: tokens,
      accountTokenProvider: accountTokens,
    );
    addTearDown(client.close);
    return client;
  }

  test('account routes send the account token, not the guest one', () async {
    final client = clientWith(
      tokens: () async => 'guest-token',
      accountTokens: () async => 'account-token',
    );
    await client.accountParticipations();
    expect(seen.single.headers['authorization'], 'Bearer account-token');
  });

  test('the bare account route sends the account token', () async {
    final client = ApiClient(
      baseUrl: Uri.parse('http://localhost:8085'),
      httpClient: MockClient((request) async {
        seen = [request];
        return http.Response(
          '{"account_id": "019c0000-0000-7000-8000-000000000001"}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
      tokenProvider: () async => 'guest-token',
      accountTokenProvider: () async => 'account-token',
    );
    addTearDown(client.close);
    await client.accountId();
    expect(seen.single.url.path, '/api/v1/account');
    expect(seen.single.headers['authorization'], 'Bearer account-token');
  });

  test('participant routes keep the guest token', () async {
    final client = clientWith(
      tokens: () async => 'guest-token',
      accountTokens: () async => 'account-token',
    );
    await client.endGuestSession();
    expect(seen.single.url.path, '/api/v1/self-scoring/session/end');
    expect(seen.single.headers['authorization'], 'Bearer guest-token');
  });

  test('an account route with no account provider uses the main one', () async {
    final client = clientWith(tokens: () async => 'main-token');
    await client.accountParticipations();
    expect(seen.single.headers['authorization'], 'Bearer main-token');
  });

  test('a signed-out account provider sends no header', () async {
    final client = clientWith(
      tokens: () async => 'guest-token',
      accountTokens: () async => null,
    );
    await client.accountParticipations();
    expect(seen.single.headers, isNot(contains('authorization')));
  });
}
