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
  final profileId = Id.parse('019c0000-0000-7000-8000-000000000101');
  final participationId = Id.parse('019c0000-0000-7000-8000-000000000201');
  final owner = Id.parse('019c0000-0000-7000-8000-000000000001');
  final profile = ParticipantProfile(
    id: profileId,
    ownerAccountId: owner,
    firstName: 'Ada',
    lastName: 'Lovelace',
    createdAt: DateTime.utc(2026, 9),
    updatedAt: DateTime.utc(2026, 9),
  );
  final participation = ContestParticipation(
    id: participationId,
    contestId: contestId,
    participantProfileId: profileId,
    roleId: SystemRoles.pilotId,
    roleName: 'Pilot',
    scoringUuid: ScoringUuid.create(),
  );

  late http.Request seen;

  ApiClient clientFor(http.Response Function(http.Request) respond) {
    final client = ApiClient(
      baseUrl: baseUrl,
      httpClient: MockClient((request) async {
        seen = request;
        return respond(request);
      }),
    );
    addTearDown(client.close);
    return client;
  }

  http.Response body(Object json, [int status = 200]) =>
      http.Response(jsonEncode(json), status, headers: jsonHeaders);

  group('participant profiles', () {
    test('participants() reads the list', () async {
      final client = clientFor(
        (_) => body({
          'participants': [profile.toJson()],
        }),
      );

      expect(await client.participants(), [profile]);
      expect(seen.method, 'GET');
      expect(seen.url.path, '/api/v1/participants');
    });

    test('participant(id) GETs one profile', () async {
      final client = clientFor((_) => body(profile.toJson()));

      expect(await client.participant(profileId), profile);
      expect(seen.url.path, '/api/v1/participants/${profileId.value}');
    });

    test('createParticipant POSTs the request', () async {
      final client = clientFor((_) => body(profile.toJson(), 201));
      final request = CreateParticipantRequest(
        id: profileId,
        firstName: 'Ada',
        lastName: 'Lovelace',
      );

      expect(await client.createParticipant(request), profile);
      expect(seen.method, 'POST');
      expect(seen.url.path, '/api/v1/participants');
      expect(jsonDecode(seen.body), request.toJson());
    });

    test('updateParticipant PUTs the request', () async {
      final client = clientFor((_) => body(profile.toJson()));
      const request = UpdateParticipantRequest(
        baseRevision: 0,
        firstName: 'Ada',
        lastName: 'Lovelace',
      );

      await client.updateParticipant(profileId, request);

      expect(seen.method, 'PUT');
      expect(seen.url.path, '/api/v1/participants/${profileId.value}');
      expect(jsonDecode(seen.body), request.toJson());
    });

    test('deleteParticipant sends DELETE and accepts 204', () async {
      final client = clientFor((_) => http.Response('', 204));

      await client.deleteParticipant(profileId);

      expect(seen.method, 'DELETE');
      expect(seen.url.path, '/api/v1/participants/${profileId.value}');
    });

    test('roles() reads the list', () async {
      final client = clientFor(
        (_) => body({
          'roles': [SystemRoles.pilot.toJson()],
        }),
      );

      expect(await client.roles(), [SystemRoles.pilot]);
      expect(seen.url.path, '/api/v1/roles');
    });
  });

  group('participations', () {
    final base = '/api/v1/contests/${contestId.value}/participations';

    test('participations(id) reads the list', () async {
      final client = clientFor(
        (_) => body({
          'participations': [participation.toJson()],
        }),
      );

      expect(await client.participations(contestId), [participation]);
      expect(seen.url.path, base);
    });

    test('addParticipation POSTs the request', () async {
      final client = clientFor((_) => body(participation.toJson(), 201));
      final request = AddParticipationRequest(
        id: participationId,
        participantProfileId: profileId,
      );

      expect(await client.addParticipation(contestId, request), participation);
      expect(seen.method, 'POST');
      expect(seen.url.path, base);
      expect(jsonDecode(seen.body), request.toJson());
    });

    test('updateParticipation PUTs the request', () async {
      final client = clientFor((_) => body(participation.toJson()));
      const request = UpdateParticipationRequest(
        baseRevision: 0,
        retiredAtRound: 2,
      );

      final result = await client.updateParticipation(
        contestId,
        participationId,
        request,
      );

      expect(result.participation, participation);
      expect(result.recalculationWarning, isNull);
      expect(seen.method, 'PUT');
      expect(seen.url.path, '$base/${participationId.value}');
      expect(jsonDecode(seen.body), request.toJson());
    });

    test('updateParticipation carries the recalculation warning', () async {
      final client = clientFor(
        (_) => body({
          ...participation.toJson(),
          'recalculation_warning':
              'Recalculation failed; the results are stale',
        }),
      );

      final result = await client.updateParticipation(
        contestId,
        participationId,
        const UpdateParticipationRequest(baseRevision: 0, retiredAtRound: 2),
      );

      expect(result.participation, participation);
      expect(
        result.recalculationWarning,
        'Recalculation failed; the results are stale',
      );
    });

    test('removeParticipation sends DELETE', () async {
      final client = clientFor((_) => http.Response('', 204));

      await client.removeParticipation(contestId, participationId);

      expect(seen.method, 'DELETE');
      expect(seen.url.path, '$base/${participationId.value}');
    });

    test('a refused removal surfaces the 409 error code', () async {
      final client = clientFor(
        (_) => body({
          'error': {
            'code': 'has_assignments',
            'message': 'assigned',
            'requestId': 'r1',
          },
        }, 409),
      );

      await expectLater(
        client.removeParticipation(contestId, participationId),
        throwsA(
          isA<ApiHttpError>().having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    });
  });
}
