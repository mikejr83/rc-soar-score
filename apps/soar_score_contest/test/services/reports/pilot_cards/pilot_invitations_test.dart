import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
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

  test('never writes an invitation link to a log', () async {
    final records = <LogRecord>[];
    final sub = Logger.root.onRecord.listen(records.add);
    addTearDown(sub.cancel);
    Logger.root.level = Level.ALL;
    final client = clientFor(
      (_) => http.Response(
        jsonEncode({
          'contest_id': contest.value,
          'can_issue': true,
          'invitations': [
            {'participation_id': lee.value, 'link': 'https://s.example/i/abc'},
          ],
        }),
        200,
        headers: headers,
      ),
    );
    await source.read(client, contest);
    expect(records.map((r) => r.message).join('\n'), isNot(contains('abc')));
  });

  test('pilots can have invitations even after retirement', () {
    ContestParticipation participation({
      RoleType role = RoleType.pilot,
      int? retiredAtRound,
    }) => ContestParticipation(
      id: lee,
      contestId: contest,
      participantProfileId: lee,
      roleId: SystemRoles.pilotId,
      roleName: 'Pilot',
      roleType: role,
      retiredAtRound: retiredAtRound,
      scoringUuid: ScoringUuid.create(),
    );
    expect(canHaveInvitation(participation()), isTrue);
    expect(canHaveInvitation(participation(retiredAtRound: 2)), isTrue);
    expect(canHaveInvitation(participation(role: RoleType.nonFlier)), isFalse);
  });

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
    expect(signedOut.sendUnavailable, SendUnavailable.signIn);
    final none = await source.read(
      clientFor((_) => error(409, 'invitations_not_available')),
      contest,
    );
    expect(none.sendUnavailable, SendUnavailable.serverIssuesNone);
  });

  test('other failures read as a failed load, not as no invitations', () async {
    final read = await source.read(
      clientFor((_) => error(500, 'internal')),
      contest,
    );
    expect(read.loadFailed, isTrue);
    expect(read.links, isEmpty);
  });

  test(
    'links the server cannot reproduce block sending with a reason',
    () async {
      final read = await source.read(
        clientFor(
          (_) => http.Response(
            jsonEncode({
              'contest_id': contest.value,
              'can_issue': true,
              'invitations': <Object>[],
              'unreproducible_participation_ids': [lee.value],
            }),
            200,
            headers: headers,
          ),
        ),
        contest,
      );
      expect(read.sendUnavailable, SendUnavailable.linksUnreproducible);
    },
  );

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

  group('send', () {
    final kim = Id.parse('019c0000-0000-7000-8000-000000000202');
    final noAddress = Id.parse('019c0000-0000-7000-8000-000000000203');
    final paths = <String>[];

    http.Response okIssue() => http.Response(
      jsonEncode({'issued_count': 3, 'invitations': <Object>[]}),
      200,
      headers: headers,
    );

    test('issues the links, then emails, and reports each pilot', () async {
      paths.clear();
      final client = clientFor((request) {
        paths.add(request.url.path);
        if (request.url.path.endsWith('/email')) {
          return http.Response(
            jsonEncode({
              'results': [
                {'participation_id': lee.value, 'status': 'accepted'},
                {'participation_id': kim.value, 'status': 'rejected'},
                {'participation_id': noAddress.value, 'skipped': 'no_email'},
              ],
            }),
            200,
            headers: headers,
          );
        }
        return okIssue();
      });
      final report = await source.send(client, contest, [lee, kim, noAddress]);
      expect(paths, [
        '/api/v1/contests/${contest.value}/invitations',
        '/api/v1/contests/${contest.value}/invitations/email',
      ]);
      expect(report.kindOf(lee), InvitationEmailKind.emailed);
      expect(report.kindOf(kim), InvitationEmailKind.notSent);
      expect(report.kindOf(noAddress), InvitationEmailKind.noAddress);
      expect(report.serviceUnavailable, isFalse);
      expect(report.needAnotherWay, [kim.value, noAddress.value]);
    });

    test('a server that cannot email still leaves the links issued', () async {
      final client = clientFor(
        (request) => request.url.path.endsWith('/email')
            ? error(409, 'email_not_available')
            : okIssue(),
      );
      final report = await source.send(client, contest, [lee]);
      expect(report.serviceUnavailable, isTrue);
      expect(report.kinds, isEmpty);
    });

    test(
      'a lost answer is asked again with the same id, then unknown',
      () async {
        final ids = <String>[];
        final client = clientFor((request) {
          if (!request.url.path.endsWith('/email')) return okIssue();
          ids.add(
            (jsonDecode(request.body) as Map<String, Object?>)['request_id']!
                as String,
          );
          return http.Response('boom', 503, headers: headers);
        });
        final report = await source.send(client, contest, [lee, kim]);
        expect(ids, hasLength(2));
        expect(ids.toSet(), hasLength(1), reason: 'same request id');
        expect(report.serviceUnavailable, isFalse);
        expect(report.kindOf(lee), InvitationEmailKind.unknown);
        expect(report.kindOf(kim), InvitationEmailKind.unknown);
      },
    );

    test(
      'a refusal on the replay of a lost first answer stays unknown',
      () async {
        var emailCalls = 0;
        final client = clientFor((request) {
          if (!request.url.path.endsWith('/email')) return okIssue();
          emailCalls++;
          return emailCalls == 1
              ? http.Response('boom', 503, headers: headers)
              : error(409, 'email_not_available');
        });
        final report = await source.send(client, contest, [lee]);
        expect(emailCalls, 2);
        expect(report.serviceUnavailable, isFalse);
        expect(report.kindOf(lee), InvitationEmailKind.unknown);
      },
    );

    test('a failed issue is a failed send and nothing is emailed', () async {
      paths.clear();
      final client = clientFor((request) {
        paths.add(request.url.path);
        return error(409, 'invitations_not_issuable');
      });
      await expectLater(
        source.send(client, contest, [lee]),
        throwsA(isA<ApiException>()),
      );
      expect(paths, hasLength(1));
    });

    test('each press uses its own request ids', () async {
      final ids = <String>[];
      final client = clientFor((request) {
        ids.add(
          (jsonDecode(request.body) as Map<String, Object?>)['request_id']!
              as String,
        );
        return request.url.path.endsWith('/email')
            ? http.Response(
                jsonEncode({'results': <Object>[]}),
                200,
                headers: headers,
              )
            : okIssue();
      });
      await source.send(client, contest, [lee]);
      await source.send(client, contest, [lee]);
      expect(ids.toSet(), hasLength(4));
    });
  });

  test('the listing carries each pilot’s latest email status', () async {
    final client = clientFor(
      (_) => http.Response(
        jsonEncode({
          'contest_id': contest.value,
          'can_issue': true,
          'invitations': [
            {
              'participation_id': lee.value,
              'link': 'https://s.example/i/abc',
              'email_status': 'bounced',
            },
          ],
        }),
        200,
        headers: headers,
      ),
    );
    final read = await source.read(client, contest);
    expect(read.emailKindOf(lee), InvitationEmailKind.notSent);
    expect(emailKindOfStatus('limited'), InvitationEmailKind.limitReached);
    expect(emailKindOfStatus('sending'), InvitationEmailKind.unknown);
    expect(emailKindOfStatus('nope'), isNull);
  });
}
