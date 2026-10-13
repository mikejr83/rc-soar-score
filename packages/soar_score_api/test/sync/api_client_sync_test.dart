import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'sync_support.dart';

void main() {
  final baseUrl = Uri.parse('http://localhost:8085');
  const jsonHeaders = <String, String>{
    'content-type': 'application/json; charset=utf-8',
  };
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

  http.Response refusal(String code, int status) => body({
    'error': {'code': code, 'message': code, 'requestId': 'r1'},
  }, status);

  final installation = Installation(
    id: installationId,
    ownerAccountId: accountId,
    label: 'Field laptop',
    platform: Platform.windows,
    createdAt: DateTime.utc(2026, 10, 13),
  );

  test('syncInfo GETs the version ranges', () async {
    final client = clientFor(
      (_) => body({
        'protocol_version': 1,
        'min_protocol_version': 1,
        'min_schema_version': 1,
        'max_schema_version': 1,
        'server_time': '2026-10-13T12:00:00.000Z',
      }),
    );

    final info = await client.syncInfo();

    expect(seen.method, 'GET');
    expect(seen.url.path, '/api/v1/sync/info');
    expect(info.accepts(protocol: 1, schema: 1), isTrue);
  });

  test('registerInstallation POSTs the request and decodes the row', () async {
    final client = clientFor((_) => body(installation.toJson(), 201));
    final request = RegisterInstallationRequest(
      id: installationId,
      label: 'Field laptop',
      platform: Platform.windows,
    );

    expect(await client.registerInstallation(request), installation);
    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/v1/installations');
    expect(jsonDecode(seen.body), request.toJson());
  });

  test('installations GETs the list', () async {
    final client = clientFor(
      (_) => body({
        'installations': [installation.toJson()],
      }),
    );

    expect(await client.installations(), [installation]);
    expect(seen.url.path, '/api/v1/installations');
  });

  test('revokeInstallation POSTs to the revoke route', () async {
    final client = clientFor((_) => body(installation.toJson()));

    await client.revokeInstallation(installationId);

    expect(seen.method, 'POST');
    expect(
      seen.url.path,
      '/api/v1/installations/${installationId.value}/revoke',
    );
  });

  test('activateInstallation POSTs and decodes the activation', () async {
    final activation = InstallationActivation(
      id: mutationId,
      contestId: contestId,
      installationId: installationId,
      activatedBy: accountId,
      kind: ActivationKind.replacement,
      activatedAt: DateTime.utc(2026, 10, 13, 12),
    );
    final client = clientFor((_) => body(activation.toJson(), 201));
    final request = ActivateInstallationRequest(
      installationId: installationId,
      kind: ActivationKind.replacement,
    );

    expect(await client.activateInstallation(contestId, request), activation);
    expect(seen.url.path, '/api/v1/contests/${contestId.value}/activations');
    expect(jsonDecode(seen.body), request.toJson());
  });

  test('reclaiming before a pull is a typed refusal', () async {
    final client = clientFor((_) => refusal('reclaim_requires_sync', 409));

    await expectLater(
      client.activateInstallation(
        contestId,
        ActivateInstallationRequest(
          installationId: installationId,
          kind: ActivationKind.reclaim,
        ),
      ),
      throwsA(
        isA<SyncRefusedError>()
            .having(
              (e) => e.reason,
              'reason',
              SyncReasonCode.reclaimRequiresSync,
            )
            .having((e) => e.statusCode, 'statusCode', 409)
            .having((e) => e.requiresUpdate, 'requiresUpdate', isFalse),
      ),
    );
  });

  test('exchange POSTs the request and decodes the results', () async {
    final client = clientFor(
      (_) => body({
        'protocol_version': 1,
        'results': [
          {
            'client_mutation_id': 'm-1',
            'outcome': 'Accepted',
            'revision': 4,
            'sequence': 42,
          },
        ],
        'changes': <Object?>[],
        'conflicts': <Object?>[],
        'server_sequence': 42,
      }),
    );
    final request = sampleRequest(mutations: [sampleMutation()]);

    final response = await client.exchange(request);

    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/v1/sync/exchange');
    expect(jsonDecode(seen.body), request.toJson());
    expect(response.results.single.outcome, MutationOutcome.accepted);
    expect(response.serverSequence, 42);
  });

  for (final (code, status) in [
    ('unsupported_protocol_version', 426),
    ('schema_too_old', 426),
  ]) {
    test('exchange throws a forced-update error for $code', () async {
      final client = clientFor((_) => refusal(code, status));

      await expectLater(
        client.exchange(sampleRequest()),
        throwsA(
          isA<SyncRefusedError>()
              .having((e) => e.reason.code, 'code', code)
              .having((e) => e.requiresUpdate, 'requiresUpdate', isTrue),
        ),
      );
    });
  }

  test('an error without a sync code stays a plain ApiHttpError', () async {
    final client = clientFor((_) => refusal('unauthorized_token', 401));

    await expectLater(
      client.exchange(sampleRequest()),
      throwsA(
        isA<ApiHttpError>()
            .having((e) => e, 'not refused', isNot(isA<SyncRefusedError>()))
            .having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });

  test('a transport failure is still an ApiNetworkError', () async {
    final client = ApiClient(
      baseUrl: baseUrl,
      httpClient: MockClient((_) async => throw http.ClientException('down')),
    );
    addTearDown(client.close);

    await expectLater(
      client.exchange(sampleRequest()),
      throwsA(isA<ApiNetworkError>()),
    );
  });

  test('systemData passes the cursor and the page token', () async {
    final client = clientFor(
      (_) => body({'changes': <Object?>[], 'system_data_seq': 9}),
    );

    final response = await client.systemData(
      afterSequence: 9,
      pageToken: 'next',
    );

    expect(seen.method, 'GET');
    expect(seen.url.path, '/api/v1/sync/system-data');
    expect(seen.url.queryParameters, {
      'after_sequence': '9',
      'page_token': 'next',
    });
    expect(response.systemDataSeq, 9);
  });

  test('systemData leaves out an absent page token', () async {
    final client = clientFor(
      (_) => body({'changes': <Object?>[], 'system_data_seq': 0}),
    );

    await client.systemData(afterSequence: 0);

    expect(seen.url.queryParameters, {'after_sequence': '0'});
  });

  test('resolveConflict POSTs the choice and decodes the result', () async {
    final client = clientFor(
      (_) => body({
        'client_mutation_id': 'r-1',
        'outcome': 'Accepted',
        'revision': 5,
        'sequence': 43,
      }),
    );
    const request = ResolveConflictRequest(
      clientMutationId: 'r-1',
      choice: ConflictResolutionChoice.tookCompeting,
    );

    final result = await client.resolveConflict(mutationId, request);

    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/v1/sync/conflicts/${mutationId.value}/resolve');
    expect(jsonDecode(seen.body), request.toJson());
    expect(result.sequence, 43);
  });

  group('download, export and import', () {
    final archive = ContestArchiveDto(
      protocolVersion: 1,
      schemaVersion: 1,
      contestId: contestId,
      serverSequence: 57,
      data: const {'contests': <Object?>[]},
    );

    test('downloadContest GETs the download route', () async {
      final client = clientFor((_) => body(archive.toJson()));

      expect((await client.downloadContest(contestId)).serverSequence, 57);
      expect(seen.url.path, '/api/v1/contests/${contestId.value}/download');
    });

    test('exportContest GETs the export route', () async {
      final client = clientFor((_) => body(archive.toJson()));

      await client.exportContest(contestId);

      expect(seen.url.path, '/api/v1/contests/${contestId.value}/export');
    });

    test('importContest POSTs the archive', () async {
      final client = clientFor((_) => body(archive.toJson(), 201));

      await client.importContest(archive);

      expect(seen.method, 'POST');
      expect(seen.url.path, '/api/v1/contests/import');
      expect(jsonDecode(seen.body), archive.toJson());
    });

    test('importing over an existing contest is a typed refusal', () async {
      final client = clientFor((_) => refusal('contest_exists', 409));

      await expectLater(
        client.importContest(archive),
        throwsA(
          isA<SyncRefusedError>().having(
            (e) => e.reason,
            'reason',
            SyncReasonCode.contestExists,
          ),
        ),
      );
    });
  });
}
