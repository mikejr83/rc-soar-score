import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

ImportProvenance _stamp({
  String type = ImportProvenance.contestEntityType,
  Id? contestId,
  String? dedupeKey,
  Map<String, Object?>? values,
}) {
  final contest = type == ImportProvenance.profileEntityType
      ? contestId
      : contestId ?? Id.create();
  return ImportProvenance(
    id: Id.create(),
    ownerAccountId: Id.create(),
    contestId: contest,
    stampedEntityType: type,
    stampedEntityId: type == ImportProvenance.contestEntityType
        ? contest!
        : Id.create(),
    sourceSystem: ImportProvenance.gliderScore,
    sourceKeys: switch (type) {
      ImportProvenance.contestEntityType => const {'comp_no': 22},
      ImportProvenance.participationEntityType => const {
        'comp_no': 22,
        'pilot_no': 98,
      },
      ImportProvenance.matrixRevisionEntityType => const {
        'comp_no': 22,
        'task_no': 1,
      },
      _ => const {'pilot_no': 98},
    },
    sourceValues: values,
    fileFingerprint: 'sha256:abc',
    dedupeKey: dedupeKey,
    importOperationId: Id.create(),
    toolVersion: '1.0.0',
    importedAt: DateTime.utc(2026, 11, 3),
  );
}

void main() {
  group('ImportProvenance', () {
    test('round-trips through JSON', () {
      final stamp = _stamp(
        dedupeKey: 'gliderscore:sha256:abc:22',
        values: {'lane_count': 6},
      );
      expect(ImportProvenance.fromJson(stamp.toJson()), stamp);
    });

    test('is director data and revisioned', () {
      final stamp = _stamp();
      expect(stamp.syncScope, SyncScope.director);
      expect(stamp.entityType, 'ImportProvenance');
      expect(
        SyncEntityCatalog.of('ImportProvenance')!.scopeKey,
        'owner_account_id',
      );
    });

    test('only a contest row carries a dedupe key and source values', () {
      expect(
        () => _stamp(
          type: ImportProvenance.participationEntityType,
          dedupeKey: 'k',
        ),
        throwsArgumentError,
      );
      expect(
        () => _stamp(
          type: ImportProvenance.participationEntityType,
          values: {'a': 1},
        ),
        throwsArgumentError,
      );
    });

    test('a matrix revision row carries source values but no dedupe key', () {
      final stamp = _stamp(
        type: ImportProvenance.matrixRevisionEntityType,
        values: {'first_round': 1, 'last_round': 10, 'groups_per_round': 3},
      );
      expect(stamp.sourceKeys, {'comp_no': 22, 'task_no': 1});
      expect(ImportProvenance.fromJson(stamp.toJson()), stamp);
      expect(
        () => _stamp(
          type: ImportProvenance.matrixRevisionEntityType,
          dedupeKey: 'gliderscore:sha256:abc:22',
        ),
        throwsArgumentError,
      );
      expect(
        () => ImportProvenance(
          id: Id.create(),
          ownerAccountId: Id.create(),
          contestId: Id.create(),
          stampedEntityType: ImportProvenance.matrixRevisionEntityType,
          stampedEntityId: Id.create(),
          sourceSystem: 'gliderscore',
          sourceKeys: const {'comp_no': 22},
          fileFingerprint: 'f',
          importOperationId: Id.create(),
          toolVersion: 'v',
          importedAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
        reason: 'task_no is required',
      );
    });

    test('only a profile row may lack a contest', () {
      expect(
        () => ImportProvenance(
          id: Id.create(),
          ownerAccountId: Id.create(),
          stampedEntityType: ImportProvenance.contestEntityType,
          stampedEntityId: Id.create(),
          sourceSystem: 'gliderscore',
          sourceKeys: const {'comp_no': 1},
          fileFingerprint: 'f',
          importOperationId: Id.create(),
          toolVersion: 'v',
          importedAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
      expect(
        _stamp(type: ImportProvenance.profileEntityType).contestId,
        isNull,
      );
    });

    test('source keys are whole numbers, sorted and the right set', () {
      ImportProvenance build(Map<String, Object?> keys) => ImportProvenance(
        id: Id.create(),
        ownerAccountId: Id.create(),
        contestId: Id.create(),
        stampedEntityType: ImportProvenance.participationEntityType,
        stampedEntityId: Id.create(),
        sourceSystem: 'gliderscore',
        sourceKeys: keys,
        fileFingerprint: 'f',
        importOperationId: Id.create(),
        toolVersion: 'v',
        importedAt: DateTime.utc(2026),
      );
      expect(build({'pilot_no': 98, 'comp_no': 22}).sourceKeys.keys.toList(), [
        'comp_no',
        'pilot_no',
      ], reason: 'stored in sorted order');
      expect(() => build({'comp_no': 22}), throwsArgumentError);
      expect(
        () => build({'comp_no': 22, 'pilot_no': 98, 'x': 1}),
        throwsArgumentError,
      );
      expect(
        () => build({'comp_no': 22.0, 'pilot_no': 98}),
        throwsArgumentError,
      );
      expect(
        () => build({'comp_no': '22', 'pilot_no': 98}),
        throwsArgumentError,
      );
    });

    test('a dedupe key must match the source and the competition', () {
      ImportProvenance build(String key) => ImportProvenance(
        id: Id.create(),
        ownerAccountId: Id.create(),
        contestId: Id.parse('019c0000-0000-7000-8000-0000000000e1'),
        stampedEntityType: ImportProvenance.contestEntityType,
        stampedEntityId: Id.parse('019c0000-0000-7000-8000-0000000000e1'),
        sourceSystem: 'gliderscore',
        sourceKeys: const {'comp_no': 22},
        fileFingerprint: 'sha256:abc',
        dedupeKey: key,
        importOperationId: Id.create(),
        toolVersion: 'v',
        importedAt: DateTime.utc(2026),
      );
      expect(build('gliderscore:sha256:abc:22'), isNotNull);
      expect(() => build('gliderscore:sha256:abc:23'), throwsArgumentError);
      expect(() => build('gliderscore:sha256:other:22'), throwsArgumentError);
    });

    test('a profile row never has a contest', () {
      expect(
        () => _stamp(
          type: ImportProvenance.profileEntityType,
          contestId: Id.create(),
        ),
        throwsArgumentError,
      );
    });

    test('a contest row stamps its own contest', () {
      expect(
        () => ImportProvenance(
          id: Id.create(),
          ownerAccountId: Id.create(),
          contestId: Id.create(),
          stampedEntityType: ImportProvenance.contestEntityType,
          stampedEntityId: Id.create(),
          sourceSystem: 'gliderscore',
          sourceKeys: const {'comp_no': 1},
          fileFingerprint: 'f',
          importOperationId: Id.create(),
          toolVersion: 'v',
          importedAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
    });

    test('an unknown entity type or source system is refused', () {
      ImportProvenance build(String type, String source) => ImportProvenance(
        id: Id.create(),
        ownerAccountId: Id.create(),
        stampedEntityType: type,
        stampedEntityId: Id.create(),
        sourceSystem: source,
        sourceKeys: const {'pilot_no': 1},
        fileFingerprint: 'f',
        importOperationId: Id.create(),
        toolVersion: 'v',
        importedAt: DateTime.utc(2026),
      );
      expect(() => build('Round', 'gliderscore'), throwsArgumentError);
      expect(() => build('ParticipantProfile', 'f3x'), throwsArgumentError);
      expect(build('ParticipantProfile', 'gliderscore'), isNotNull);
    });

    test('blank text is refused', () {
      expect(
        () => ImportProvenance(
          id: Id.create(),
          ownerAccountId: Id.create(),
          contestId: Id.create(),
          stampedEntityType: 'Contest',
          stampedEntityId: Id.create(),
          sourceSystem: ' ',
          sourceKeys: const {'comp_no': 1},
          fileFingerprint: 'f',
          importOperationId: Id.create(),
          toolVersion: 'v',
          importedAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
    });
  });

  group('ProvenanceKeys', () {
    test('canonical form sorts keys and has no whitespace', () {
      expect(
        ProvenanceKeys.canonicalSourceKeys({'pilot_no': 98, 'comp_no': 22}),
        '{"comp_no":22,"pilot_no":98}',
      );
      expect(ProvenanceKeys.canonicalSourceKeys({}), '{}');
    });

    test('equal keys give equal text whatever the insertion order', () {
      expect(
        ProvenanceKeys.canonicalSourceKeys({'a': 1, 'b': 2}),
        ProvenanceKeys.canonicalSourceKeys({'b': 2, 'a': 1}),
      );
    });

    test('only whole numbers are allowed', () {
      for (final bad in [1.5, '1', null, true]) {
        expect(
          () => ProvenanceKeys.canonicalSourceKeys({'comp_no': bad}),
          throwsArgumentError,
          reason: '$bad',
        );
      }
    });

    test('the contest dedupe key', () {
      expect(
        ProvenanceKeys.contestDedupeKey(
          sourceSystem: 'gliderscore',
          fileFingerprint: 'sha256:abc',
          compNo: 22,
        ),
        'gliderscore:sha256:abc:22',
      );
    });
  });
}
