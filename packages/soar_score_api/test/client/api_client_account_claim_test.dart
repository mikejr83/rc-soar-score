import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final local = Id.parse('019c0000-0000-7000-8000-00000000a001');
  late http.Request seen;

  ApiClient clientFor(http.Response Function(http.Request) respond) {
    final client = ApiClient(
      baseUrl: Uri.parse('http://localhost:8085'),
      httpClient: MockClient((request) async {
        seen = request;
        return respond(request);
      }),
    );
    addTearDown(client.close);
    return client;
  }

  test('claimLocalAccount posts the Local id and reads the answer', () async {
    final client = clientFor(
      (_) => http.Response(
        jsonEncode({
          'local_account_id': local.value,
          'claimed_at': '2026-10-13T12:00:00.000Z',
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );

    final claim = await client.claimLocalAccount(
      ClaimLocalAccountRequest(localAccountId: local),
    );

    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/v1/account/local-claims');
    expect(jsonDecode(seen.body), {'local_account_id': local.value});
    expect(claim.localAccountId, local);
    expect(claim.claimedAt, DateTime.utc(2026, 10, 13, 12));
  });

  test('a claim by another account is an ApiHttpError with status 409', () {
    final client = clientFor(
      (_) => http.Response(
        jsonEncode({
          'error': {'code': 'already_claimed', 'message': 'claimed'},
        }),
        409,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );

    expect(
      client.claimLocalAccount(ClaimLocalAccountRequest(localAccountId: local)),
      throwsA(isA<ApiHttpError>().having((e) => e.statusCode, 'status', 409)),
    );
  });
}
