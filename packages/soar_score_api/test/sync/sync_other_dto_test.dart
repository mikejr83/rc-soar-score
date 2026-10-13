import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'sync_support.dart';

void main() {
  group('SyncInfoDto', () {
    final info = SyncInfoDto(
      protocolVersion: 2,
      minProtocolVersion: 1,
      minSchemaVersion: 3,
      maxSchemaVersion: 5,
      serverTime: DateTime.utc(2026, 10, 13, 12),
    );

    test('round-trips through snake_case JSON', () {
      expect(info.toJson()['min_schema_version'], 3);
      expect(SyncInfoDto.fromJson(info.toJson()).toJson(), info.toJson());
    });

    test('accepts versions inside both ranges only', () {
      expect(info.accepts(protocol: 1, schema: 3), isTrue);
      expect(info.accepts(protocol: 2, schema: 5), isTrue);
      expect(info.accepts(protocol: 0, schema: 4), isFalse);
      expect(info.accepts(protocol: 3, schema: 4), isFalse);
      expect(info.accepts(protocol: 1, schema: 2), isFalse);
      expect(info.accepts(protocol: 1, schema: 6), isFalse);
    });
  });

  test('RegisterInstallationRequest encodes the platform text', () {
    final request = RegisterInstallationRequest(
      id: installationId,
      label: 'Field laptop',
      platform: Platform.windows,
    );

    expect(request.toJson(), {
      'id': installationId.value,
      'label': 'Field laptop',
      'platform': 'Windows',
    });
  });

  test('ActivateInstallationRequest encodes the activation kind', () {
    final request = ActivateInstallationRequest(
      installationId: installationId,
      kind: ActivationKind.reclaim,
    );

    expect(request.toJson(), {
      'installation_id': installationId.value,
      'kind': 'Reclaim',
    });
  });

  group('ResolveConflictRequest', () {
    test('leaves out the payload unless merging', () {
      const request = ResolveConflictRequest(
        clientMutationId: 'r-1',
        choice: ConflictResolutionChoice.keptAccepted,
      );

      expect(request.toJson(), {
        'client_mutation_id': 'r-1',
        'choice': 'KeptAccepted',
      });
    });

    test('carries the merged payload', () {
      const request = ResolveConflictRequest(
        clientMutationId: 'r-2',
        choice: ConflictResolutionChoice.merged,
        payload: {'time_flown': 545},
      );

      expect(ResolveConflictRequest.fromJson(request.toJson()).payload, {
        'time_flown': 545,
      });
    });
  });

  test('SystemDataResponse decodes changes and the position', () {
    final response = SystemDataResponse.fromJson({
      'changes': [
        {
          'sequence': 9,
          'entity_type': 'role',
          'entity_id': entityId.value,
          'revision': 1,
          'payload': <String, Object?>{},
        },
      ],
      'system_data_seq': 9,
    });

    expect(response.changes.single.entityType, 'role');
    expect(response.systemDataSeq, 9);
    expect(response.nextPageToken, isNull);
  });

  test('ContestArchiveDto round-trips with its data', () {
    final archive = ContestArchiveDto(
      protocolVersion: 1,
      schemaVersion: 1,
      contestId: contestId,
      serverSequence: 57,
      data: const {
        'contests': [
          {'name': 'Spring Open'},
        ],
      },
    );

    expect(
      ContestArchiveDto.fromJson(archive.toJson()).toJson(),
      archive.toJson(),
    );
  });
}
