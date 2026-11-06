import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

String _fixture(String name) =>
    File('fixtures/self_scoring/$name.json').readAsStringSync();

void main() {
  final baseUrl = Uri.parse('http://localhost:8085');
  const jsonHeaders = <String, String>{
    'content-type': 'application/json; charset=utf-8',
  };

  late http.Request seen;

  ApiClient clientFor(
    http.Response Function(http.Request) respond, {
    TokenProvider? tokenProvider,
  }) {
    final client = ApiClient(
      baseUrl: baseUrl,
      tokenProvider: tokenProvider,
      httpClient: MockClient((request) async {
        seen = request;
        return respond(request);
      }),
    );
    addTearDown(client.close);
    return client;
  }

  http.Response fixture(String name, [int status = 200]) =>
      http.Response(_fixture(name), status, headers: jsonHeaders);

  test('resolveInvitation POSTs the credential without a token', () async {
    final client = clientFor(
      (_) => fixture('resolve_invitation_response'),
      tokenProvider: () async => 'stale-token',
    );

    final answer = await client.resolveInvitation(
      const ResolveInvitationRequest(credential: 'abc'),
    );

    expect(answer.sessionToken, 'example-session-token');
    expect(answer.participant.pilotName, 'Alex Rivera');
    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/v1/self-scoring/invitations/resolve');
    expect(seen.headers.containsKey('authorization'), isFalse);
    expect(jsonDecode(seen.body), containsPair('credential', 'abc'));
  });

  test('participant reads send the session token', () async {
    final client = clientFor(
      (request) => switch (request.url.path) {
        '/api/v1/self-scoring/overview' => fixture('participant_overview'),
        '/api/v1/self-scoring/rounds/2/entry' => fixture('entry_context'),
        '/api/v1/self-scoring/rounds/1/group-results' => fixture(
          'group_results',
        ),
        _ => fixture('overall_results'),
      },
      tokenProvider: () async => 'session-1',
    );

    expect((await client.participantOverview()).rounds, hasLength(3));
    expect(seen.headers['authorization'], 'Bearer session-1');
    expect((await client.participantEntryContext(2)).group, 'B');
    expect(seen.url.path, '/api/v1/self-scoring/rounds/2/entry');
    expect((await client.participantGroupResults(1)).rows, hasLength(3));
    expect(seen.url.path, '/api/v1/self-scoring/rounds/1/group-results');
    expect((await client.participantOverallResults()).yourPlace, 2);
    expect(seen.url.query, isEmpty);
    await client.participantOverallResults(asOfRound: 1);
    expect(seen.url.queryParameters, {'round': '1'});
  });

  test('submitParticipantScore POSTs the mutation id and components', () async {
    final client = clientFor((_) => fixture('submit_response'));

    final answer = await client.submitParticipantScore(
      2,
      SubmitParticipantScoreRequest.fromJson(
        jsonDecode(_fixture('submit_request')) as Map<String, dynamic>,
      ),
    );

    expect(answer.score.flightScore, 962.5);
    expect(answer.nextRound, 3);
    expect(seen.url.path, '/api/v1/self-scoring/rounds/2/scores');
    expect(
      jsonDecode(seen.body),
      containsPair('client_mutation_id', 'entry-7-2-1'),
    );
  });

  test('a refusal exposes the participant error', () async {
    final client = clientFor(
      (_) => fixture('error_score_already_submitted', 409),
    );

    try {
      await client.submitParticipantScore(
        2,
        const SubmitParticipantScoreRequest(
          clientMutationId: 'x',
          matrixRevision: 3,
          components: {},
        ),
      );
      fail('expected a refusal');
    } on ApiHttpError catch (error) {
      expect(error.statusCode, 409);
      final refusal = error.participantError!;
      expect(refusal.code, ParticipantErrorCodes.scoreAlreadySubmitted);
      expect(refusal.acceptedScore?.flightScore, 962.5);
    }
  });

  test('a body that is not a participant error reads as null', () {
    final error = ApiHttpError(
      'bad gateway',
      statusCode: 502,
      body: '<html>',
      requestUri: Uri.parse('http://x'),
    );
    expect(error.participantError, isNull);
  });

  test(
    'contestInvitations and issueInvitations call the director routes',
    () async {
      const id = '019c0000-0000-7000-8000-000000000020';
      const participation = '019c0000-0000-7000-8000-000000000201';
      final client = clientFor((request) {
        final created = request.method == 'POST';
        return http.Response(
          jsonEncode({
            if (created)
              'issued_count': 1
            else ...{
              'contest_id': id,
              'can_issue': false,
              'cannot_issue_code': 'invitations_not_issuable',
              'cannot_issue_reason': 'not now',
            },
            'invitations': [
              {
                'participation_id': participation,
                'link': 'https://score.example/invitations/abc.def',
              },
            ],
          }),
          200,
          headers: jsonHeaders,
        );
      });

      final listed = await client.contestInvitations(Id.parse(id));
      expect(seen.method, 'GET');
      expect(seen.url.path, '/api/v1/contests/$id/invitations');
      expect(listed.canIssue, isFalse);
      expect(listed.cannotIssueReason, 'not now');
      expect(listed.invitations.single.participationId.value, participation);

      final issued = await client.issueInvitations(
        Id.parse(id),
        IssueInvitationsRequest(
          requestId: 'r1',
          participationIds: [Id.parse(participation)],
        ),
      );
      expect(seen.method, 'POST');
      expect(jsonDecode(seen.body), {
        'request_id': 'r1',
        'participation_ids': [participation],
      });
      expect(issued.issuedCount, 1);
      expect(issued.invitations.single.link, endsWith('/invitations/abc.def'));
    },
  );
}
