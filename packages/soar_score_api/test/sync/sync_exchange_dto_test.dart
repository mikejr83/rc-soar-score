import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'sync_support.dart';

void main() {
  group('SyncScopeDto', () {
    test('a contest scope leaves out owner_account_id', () {
      expect(SyncScopeDto.contest(contestId).toJson(), {
        'contest_id': contestId.value,
      });
    });

    test('an owner scope leaves out contest_id', () {
      expect(SyncScopeDto.owner(accountId).toJson(), {
        'owner_account_id': accountId.value,
      });
    });

    test('decoding needs exactly one of the two ids', () {
      expect(() => SyncScopeDto.fromJson({}), throwsA(anything));
      expect(
        () => SyncScopeDto.fromJson({
          'contest_id': contestId.value,
          'owner_account_id': accountId.value,
        }),
        throwsA(anything),
      );
    });
  });

  group('SyncExchangeRequest', () {
    test('encodes snake_case keys and the mutations in order', () {
      final json = sampleRequest(
        mutations: [
          sampleMutation(),
          sampleMutation(dependsOn: mutationId),
        ],
      ).toJson();

      expect(json['protocol_version'], 1);
      expect(json['schema_version'], 1);
      expect(json['installation_id'], installationId.value);
      expect(json['scope'], {'contest_id': contestId.value});
      expect(json['last_acknowledged_sequence'], 41);
      expect(json['page_token'], isNull);
      final mutations = (json['mutations'] as List).cast<Map>();
      expect(mutations, hasLength(2));
      expect(mutations.first['client_mutation_id'], 'm-1');
      expect(mutations.first['authority'], 'Director');
      expect(mutations.first['client_time'], '2026-10-13T12:00:00.000Z');
      expect(mutations.last['depends_on_mutation_id'], mutationId.value);
    });

    test('round-trips through JSON', () {
      final request = sampleRequest(mutations: [sampleMutation()]);
      final decoded = SyncExchangeRequest.fromJson(request.toJson());

      expect(decoded.toJson(), request.toJson());
      expect(decoded.mutations.single.baseRevision, 3);
      expect(decoded.mutations.single.payload, {'time_flown': 540});
    });

    test('a pull has no mutations', () {
      expect(sampleRequest().toJson()['mutations'], isEmpty);
    });
  });

  group('SyncExchangeResponse', () {
    final json = {
      'protocol_version': 1,
      'results': [
        {
          'client_mutation_id': 'm-1',
          'outcome': 'Accepted',
          'revision': 4,
          'sequence': 42,
        },
        {
          'client_mutation_id': 'm-2',
          'outcome': 'Rejected',
          'reason_code': 'locked',
          'current_revision': 4,
        },
        {
          'client_mutation_id': 'm-3',
          'outcome': 'Skipped',
          'reason_code': 'dependency_failed',
          'depends_on': 'm-2',
        },
        {
          'client_mutation_id': 'm-4',
          'outcome': 'Conflict',
          'reason_code': 'a_code_from_the_future',
          'current_revision': 7,
        },
      ],
      'changes': [
        {
          'sequence': 42,
          'entity_type': 'official_score',
          'entity_id': entityId.value,
          'revision': 4,
          'payload': {'time_flown': 540},
        },
      ],
      'conflicts': [
        {'id': mutationId.value, 'requires_action': true},
      ],
      'next_page_token': 'next',
      'server_sequence': 57,
    };

    test('decodes every outcome with its fields', () {
      final response = SyncExchangeResponse.fromJson(json);

      expect(response.results.map((r) => r.outcome.name), [
        'accepted',
        'rejected',
        'skipped',
        'conflict',
      ]);
      expect(response.results[0].revision, 4);
      expect(response.results[0].sequence, 42);
      expect(response.results[1].currentRevision, 4);
      expect(response.results[2].dependsOn, 'm-2');
      expect(response.changes.single.sequence, 42);
      expect(response.conflicts.single.requiresAction, isTrue);
      expect(response.nextPageToken, 'next');
      expect(response.serverSequence, 57);
    });

    test('reason is typed for a known code and null for an unknown one', () {
      final results = SyncExchangeResponse.fromJson(json).results;

      expect(results[0].reason, isNull);
      expect(results[1].reason, SyncReasonCode.locked);
      expect(results[2].reason, SyncReasonCode.dependencyFailed);
      expect(results[3].reason, isNull);
      expect(results[3].reasonCode, 'a_code_from_the_future');
    });

    test('round-trips through JSON', () {
      final response = SyncExchangeResponse.fromJson(json);

      expect(
        SyncExchangeResponse.fromJson(response.toJson()).toJson(),
        response.toJson(),
      );
    });
  });
}
