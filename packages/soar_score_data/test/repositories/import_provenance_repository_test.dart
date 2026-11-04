import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/example_entities.dart';
import '../support/example_rows.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  late Repository repository;

  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    await loadExamples(inst);
    repository = Repository(inst.db);
  });
  tearDown(() => inst.close());

  group('ImportProvenanceRepository', () {
    late core.ImportProvenanceRepository repo;
    setUp(() => repo = repository.importProvenanceRepository);

    final examples = [
      for (final row in exampleRows('import_provenance'))
        core.ImportProvenance.fromJson(row),
    ];
    final contestStamp = examples.firstWhere(
      (s) => s.dedupeKey != null,
      orElse: () => throw StateError('no contest stamp in the examples'),
    );

    /// A stamp like [base] for another entity of the same kind (a profile
    /// keeps its entity and gets another import operation).
    core.ImportProvenance another(
      core.ImportProvenance base, {
      core.Id? owner,
      String? dedupeKey,
    }) {
      final isProfile = base.stampedEntityType == 'ParticipantProfile';
      final entity = isProfile ? base.stampedEntityId : core.Id.create();
      return core.ImportProvenance.fromJson({
        ...base.toJson(),
        'id': core.Id.create().value,
        'owner_account_id': (owner ?? base.ownerAccountId).value,
        'stamped_entity_id': entity.value,
        if (base.stampedEntityType == 'Contest') 'contest_id': entity.value,
        'import_operation_id': core.Id.create().value,
        'dedupe_key': dedupeKey ?? base.dedupeKey,
        'revision': 0,
      });
    }

    test('reads back the example stamps unchanged', () async {
      for (final stamp in examples) {
        expect(await repo.findById(stamp.id), stamp);
      }
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('lists the stamps of a contest and finds one by entity', () async {
      final listed = await repo.listForContest(contestStamp.contestId!);
      expect(listed.map((s) => s.id), containsAll([contestStamp.id]));
      expect(
        listed.every((s) => s.contestId == contestStamp.contestId),
        isTrue,
      );
      expect(
        (await repo.listForEntity(contestStamp.stampedEntityId))
            .map((s) => s.id),
        [contestStamp.id],
      );
      expect(await repo.listForEntity(core.Id.create()), isEmpty);
    });

    test('finds a contest stamp by owner and dedupe key', () async {
      final key = contestStamp.dedupeKey!;
      expect(
        (await repo.findByDedupeKey(contestStamp.ownerAccountId, key))?.id,
        contestStamp.id,
      );
      expect(
        await repo.findByDedupeKey(core.Id.create(), key),
        isNull,
        reason: 'another owner has not imported it',
      );
      expect(
        await repo.findByDedupeKey(contestStamp.ownerAccountId, 'other'),
        isNull,
      );
    });

    test('refuses a second stamp with the same owner and key', () async {
      await expectLater(
        repo.save(another(contestStamp), metadata: metadata()),
        throwsA(anything),
      );
    });

    test('lets another owner stamp the same competition', () async {
      final saved = await repo.save(
        another(contestStamp, owner: core.Id.create()),
        metadata: metadata(),
      );
      expect(saved.revision, 0);
    });

    test('stamps without a dedupe key never clash', () async {
      final participation = examples.firstWhere(
        (s) => s.stampedEntityType == 'ContestParticipation',
      );
      await repo.save(another(participation), metadata: metadata());
      await repo.save(another(participation), metadata: metadata());
    });

    test('a contest or participation is stamped once', () async {
      final participation = examples.firstWhere(
        (s) => s.stampedEntityType == 'ContestParticipation',
      );
      for (final base in [contestStamp, participation]) {
        final again = core.ImportProvenance.fromJson({
          ...base.toJson(),
          'id': core.Id.create().value,
          'import_operation_id': core.Id.create().value,
          'dedupe_key': null,
        });
        await expectLater(
          repo.save(again, metadata: metadata()),
          throwsA(anything),
          reason: 'second stamp of one ${base.stampedEntityType}',
        );
      }
    });

    test('a profile is stamped once per import operation', () async {
      final profile = examples.firstWhere((s) => s.contestId == null);
      final sameOperation = core.ImportProvenance.fromJson({
        ...profile.toJson(),
        'id': core.Id.create().value,
      });
      await expectLater(
        repo.save(sameOperation, metadata: metadata()),
        throwsA(anything),
      );
    });

    test('a shared profile lists one stamp per import operation', () async {
      final profile = examples.firstWhere((s) => s.contestId == null);
      final second = await repo.save(another(profile), metadata: metadata());
      final listed = await repo.listForEntity(profile.stampedEntityId);
      expect(listed.map((s) => s.id), containsAll([profile.id, second.id]));
      expect(listed, hasLength(2));
    });

    test('save bumps the revision and refuses a stale read', () async {
      final read = (await repo.findById(contestStamp.id))!;
      final updated = await repo.save(read, metadata: metadata());
      expect(updated.revision, read.revision + 1);
      await expectLater(
        repo.save(read, metadata: metadata()),
        throwsA(isA<core.StaleRevisionError>()),
      );
    });

    test('delete removes the stamp and records a tombstone', () async {
      final tombstones = await inst.count('tombstones');
      expect(await repo.delete(contestStamp.id, metadata: metadata()), isTrue);
      expect(await repo.findById(contestStamp.id), isNull);
      expect(await inst.count('tombstones'), tombstones + 1);
      expect(await repo.delete(contestStamp.id, metadata: metadata()), isFalse);
    });

    test(
      'deleting a contest deletes its stamps, not a profile stamp',
      () async {
        final contest = (await repository.contestRepository.getAll()).first;
        final onContest = await repo.save(
          core.ImportProvenance.fromJson({
            ...contestStamp.toJson(),
            'id': core.Id.create().value,
            'contest_id': contest.id.value,
            'stamped_entity_id': contest.id.value,
            'source_keys': {'comp_no': 1},
            'file_fingerprint': 'sha256:test',
            'dedupe_key': 'gliderscore:sha256:test:1',
            'revision': 0,
          }),
          metadata: metadata(),
        );
        final profileStamp = examples.firstWhere((s) => s.contestId == null);
        final tombstones = await inst.count('tombstones');

        expect(
          await repository.contestRepository.delete(
            contest.id,
            metadata: metadata(),
          ),
          isTrue,
        );

        expect(await repo.findById(onContest.id), isNull);
        expect(await repo.findById(profileStamp.id), isNotNull);
        expect(await inst.count('tombstones'), greaterThan(tombstones + 1));
      },
    );
  });
}
