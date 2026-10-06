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
  final profileId = Id.parse('019c0000-0000-7000-8000-000000000030');
  final contest = Contest(
    id: contestId,
    name: 'Spring Open',
    startDateTime: DateTime.utc(2026, 10, 17, 14),
    endDateTime: DateTime.utc(2026, 10, 18, 22),
    timezone: 'America/Denver',
    createdAt: DateTime.utc(2026, 9),
    updatedAt: DateTime.utc(2026, 9),
  );
  ContestConfigurationRevision revision(int number) =>
      ContestConfigurationRevision(
        id: Id.parse('019c0000-0000-7000-8000-00000000004$number'),
        contestId: contestId,
        revisionNumber: number,
        disciplineProfileId: profileId,
        config: ContestConfig(core: {}, discipline: {}),
        createdBy: Id.parse('019c0000-0000-7000-8000-000000000050'),
        createdAt: DateTime.utc(2026, 9),
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

  test('configuration(id) GETs the latest revision', () async {
    final client = clientFor((_) => body(revision(1).toJson()));

    expect(await client.configuration(contestId), revision(1));
    expect(seen.method, 'GET');
    expect(seen.url.path, '/api/v1/contests/${contestId.value}/configuration');
  });

  test('configurationRevisions reads the revisions list', () async {
    final client = clientFor(
      (_) => body({
        'revisions': [revision(1).toJson(), revision(2).toJson()],
      }),
    );

    expect(await client.configurationRevisions(contestId), [
      revision(1),
      revision(2),
    ]);
    expect(
      seen.url.path,
      '/api/v1/contests/${contestId.value}/configuration/revisions',
    );
  });

  test('saveConfiguration POSTs the request and decodes both parts', () async {
    final saved = SavedConfiguration(revision: revision(1), contest: contest);
    final client = clientFor((_) => body(saved.toJson(), 201));
    final request = SaveConfigurationRequest(
      baseRevisionNumber: 0,
      disciplineProfileId: profileId,
      config: ContestConfig(core: {}, discipline: {}),
    );

    expect(await client.saveConfiguration(contestId, request), saved);
    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/v1/contests/${contestId.value}/configuration');
    expect(jsonDecode(seen.body), request.toJson());
  });

  test('a refused save surfaces the 409 error code', () async {
    final client = clientFor(
      (_) => body({
        'error': {
          'code': 'configuration_fixed',
          'message': 'fixed',
          'requestId': 'r1',
        },
      }, 409),
    );

    await expectLater(
      client.saveConfiguration(
        contestId,
        SaveConfigurationRequest(
          baseRevisionNumber: 1,
          disciplineProfileId: profileId,
          config: ContestConfig(core: {}, discipline: {}),
        ),
      ),
      throwsA(
        isA<ApiHttpError>()
            .having((e) => e.statusCode, 'status', 409)
            .having((e) => e.error?.code, 'code', 'configuration_fixed'),
      ),
    );
  });
}
