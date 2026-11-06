import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/pilot_invitations.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  final contest = Id.parse('019c0000-0000-7000-8000-000000000020');
  final lee = Id.parse('019c0000-0000-7000-8000-000000000201');
  const headers = {'content-type': 'application/json; charset=utf-8'};
  const source = ApiPilotInvitationSource();

  ApiClient clientFor(http.Response Function(http.Request) respond) =>
      ApiClient(
        baseUrl: Uri.parse('http://localhost:8085'),
        httpClient: MockClient((request) async => respond(request)),
      );

  http.Response error(int status, String code) => http.Response(
    jsonEncode({
      'error': {'code': code, 'message': 'no'},
    }),
    status,
    headers: headers,
  );

  test(
    'reads the links by participation and the reason it cannot send',
    () async {
      final client = clientFor(
        (_) => http.Response(
          jsonEncode({
            'contest_id': contest.value,
            'can_issue': false,
            'cannot_issue_code': 'invitations_not_issuable',
            'cannot_issue_reason': 'this one is completed',
            'invitations': [
              {
                'participation_id': lee.value,
                'link': 'https://s.example/i/abc',
              },
            ],
          }),
          200,
          headers: headers,
        ),
      );
      final read = await source.read(client, contest);
      expect(read.linkOf(lee), 'https://s.example/i/abc');
      expect(read.synchronized, isTrue);
      expect(read.sendUnavailableReason, 'this one is completed');
    },
  );

  test('a contest the server does not have is not synchronized', () async {
    final read = await source.read(
      clientFor((_) => error(404, 'not_found')),
      contest,
    );
    expect(read.synchronized, isFalse);
    expect(read.links, isEmpty);
  });

  test('no sign-in or a server that issues none read as unavailable', () async {
    final signedOut = await source.read(
      clientFor((_) => error(401, 'unauthorized')),
      contest,
    );
    expect(
      signedOut.sendUnavailableReason,
      ApiPilotInvitationSource.signInReason,
    );
    final none = await source.read(
      clientFor((_) => error(409, 'invitations_not_available')),
      contest,
    );
    expect(
      none.sendUnavailableReason,
      ApiPilotInvitationSource.notAvailableReason,
    );
  });

  test('other failures are not hidden', () async {
    await expectLater(
      source.read(clientFor((_) => error(500, 'internal')), contest),
      throwsA(isA<ApiHttpError>()),
    );
  });

  test('send issues for the chosen pilots only, with no email field', () async {
    late http.Request seen;
    final client = clientFor((request) {
      seen = request;
      return http.Response(
        jsonEncode({'issued_count': 1, 'invitations': []}),
        200,
        headers: headers,
      );
    });
    await source.send(client, contest, [lee]);
    expect(seen.method, 'POST');
    final body = jsonDecode(seen.body) as Map<String, dynamic>;
    expect(body['participation_ids'], [lee.value]);
    expect(body['request_id'], isNotEmpty);
    expect(body.keys, unorderedEquals(['request_id', 'participation_ids']));
  });

  test('a failed send throws, so nothing is shown as sent', () async {
    await expectLater(
      source.send(
        clientFor((_) => error(409, 'invitations_not_issuable')),
        contest,
        [lee],
      ),
      throwsA(isA<ApiHttpError>()),
    );
  });
}
