import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final baseUrl = Uri.parse('http://localhost:8085');
  const jsonHeaders = <String, String>{
    'content-type': 'application/json; charset=utf-8',
  };
  final contestId = Id.parse('019c0000-0000-7000-8000-000000000020');
  final contest = Contest(
    id: contestId,
    name: 'Spring Open',
    startDateTime: DateTime.utc(2026, 10, 17, 14),
    endDateTime: DateTime.utc(2026, 10, 18, 22),
    timezone: 'America/Denver',
    createdAt: DateTime.utc(2026, 9),
    updatedAt: DateTime.utc(2026, 9),
  );

  late http.Request seen;

  ApiClient clientFor(http.Response Function(http.Request) respond) {
    final client = ApiClient(
      baseUrl: baseUrl,
      httpClient: MockClient((request) async {
        seen = request;
        return respond(request);
      }),
      tokenProvider: () async => 'token-1',
    );
    addTearDown(client.close);
    return client;
  }

  http.Response ok([int status = 200]) =>
      http.Response(jsonEncode(contest.toJson()), status, headers: jsonHeaders);

  test('contest(id) GETs /api/v1/contests/{id}', () async {
    final client = clientFor((_) => ok());

    expect(await client.contest(contestId), contest);
    expect(seen.method, 'GET');
    expect(seen.url.path, '/api/v1/contests/${contestId.value}');
    expect(seen.headers['authorization'], 'Bearer token-1');
  });

  test('createContest POSTs the request as JSON', () async {
    final client = clientFor((_) => ok(201));
    final request = CreateContestRequest(
      id: contestId,
      name: 'Spring Open',
      startDateTime: DateTime.utc(2026, 10, 17, 14),
      endDateTime: DateTime.utc(2026, 10, 18, 22),
      timezone: 'America/Denver',
    );

    expect(await client.createContest(request), contest);
    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/v1/contests');
    expect(seen.headers['content-type'], contains('application/json'));
    expect(jsonDecode(seen.body), request.toJson());
  });

  test('updateContest PUTs to the contest', () async {
    final client = clientFor((_) => ok());
    final request = UpdateContestRequest(
      baseRevision: 0,
      name: 'Renamed',
      startDateTime: DateTime.utc(2026, 10, 17, 14),
      endDateTime: DateTime.utc(2026, 10, 18, 22),
    );

    await client.updateContest(contestId, request);

    expect(seen.method, 'PUT');
    expect(seen.url.path, '/api/v1/contests/${contestId.value}');
    expect(jsonDecode(seen.body), request.toJson());
  });

  test('applyContestAction POSTs to the actions route', () async {
    final client = clientFor((_) => ok());

    await client.applyContestAction(
      contestId,
      const ContestActionRequest(action: ContestAction.lock, baseRevision: 4),
    );

    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/v1/contests/${contestId.value}/actions');
    expect(jsonDecode(seen.body), {'action': 'lock', 'base_revision': 4});
  });

  test('auditEvents GETs the route with its filters and decodes', () async {
    final event = AuditEvent(
      id: Id.parse('019c0000-0000-7000-8000-000000000031'),
      entityType: 'Contest',
      entityId: contestId,
      contestId: contestId,
      action: AuditAction.stateTransition,
      actorId: Id.parse('019c0000-0000-7000-8000-000000000001'),
      authority: Authority.director,
      serverTimestamp: DateTime.utc(2026, 10, 18, 9),
      reason: 'lock: AdminLock Unlocked → Locked',
    );
    final client = clientFor(
      (_) => http.Response(
        jsonEncode({
          'audit_events': [AuditEventDto.fromEvent(event).toJson()],
        }),
        200,
        headers: jsonHeaders,
      ),
    );

    final events = await client.auditEvents(
      contestId,
      action: AuditAction.stateTransition,
      limit: 5,
      offset: 10,
    );

    expect(seen.method, 'GET');
    expect(seen.url.path, '/api/v1/contests/${contestId.value}/audit-events');
    expect(seen.url.queryParameters, {
      'action': 'StateTransition',
      'limit': '5',
      'offset': '10',
    });
    expect(events.single.transition, ContestAction.lock);
    expect(events.single.actorId, event.actorId);
    expect(events.single.serverTimestamp, event.serverTimestamp);
  });

  test('a 409 carries the server error code', () async {
    final client = clientFor(
      (_) => http.Response(
        '{"error":{"code":"stale_revision","message":"m","requestId":null}}',
        409,
        headers: jsonHeaders,
      ),
    );

    await expectLater(
      client.applyContestAction(
        contestId,
        const ContestActionRequest(action: ContestAction.lock, baseRevision: 0),
      ),
      throwsA(
        isA<ApiHttpError>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having((e) => e.error?.code, 'error.code', 'stale_revision'),
      ),
    );
  });
}
