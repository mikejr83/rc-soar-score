import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/example_entities.dart';
import '../support/example_rows.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  group('ContestConfigurationRevisionRepository', () {
    late Installation inst;
    late core.ContestConfigurationRevisionRepository repo;

    setUp(() async {
      inst = await Installation.open(backend, profile: DatabaseProfile.server);
      await loadExamples(inst);
      repo = ContestConfigurationRevisionRepository(inst.db);
    });
    tearDown(() => inst.close());

    final example = core.ContestConfigurationRevision.fromJson(
      exampleRows('contest_configuration_revision').single,
    );

    core.ContestConfigurationRevision revision(int number) =>
        core.ContestConfigurationRevision.fromJson({
          ...exampleRows('contest_configuration_revision').single,
          'id': core.Id.create().value,
          'revision_number': number,
        });

    test('reads back the example revision unchanged', () async {
      expect(await repo.findById(example.id), example);
    });

    test('findById returns null for an unknown id', () async {
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('append stores the revision and records one mutation', () async {
      final before = await inst.count('mutation_records');
      final next = revision(3);

      expect(await repo.append(next, metadata: metadata()), next);

      expect(await repo.findById(next.id), next);
      expect(await inst.count('mutation_records'), before + 1);
    });

    test('append refuses an id that is already stored', () async {
      expect(
        repo.append(example, metadata: metadata()),
        throwsA(isA<core.AlreadyStoredError>()),
      );
    });

    core.AuditEvent audit(core.Id revisionId) => core.AuditEvent(
      id: core.Id.create(),
      entityType: 'ContestConfigurationRevision',
      entityId: revisionId,
      contestId: example.contestId,
      action: core.AuditAction.configurationSaved,
      authority: core.Authority.director,
      serverTimestamp: DateTime.utc(2026, 5, 1, 12),
    );

    test('appendWithContest stores the audit event in the same '
        'transaction', () async {
      final next = revision(3);
      final contest = (await Repository(inst.db).contestRepository.findById(
        example.contestId,
      ))!;

      final stored = await repo.appendWithContest(
        next,
        contest: contest,
        metadata: metadata(),
        audit: audit(next.id),
      );

      expect(stored.revision, next);
      final events = await Repository(inst.db).auditEventRepository
          .listForContest(
            example.contestId,
            action: core.AuditAction.configurationSaved,
          );
      expect(events, hasLength(1));
      expect(events.single.entityId, next.id);
    });

    test('appendWithContest with a stale contest stores no event', () async {
      final next = revision(3);
      final stale = (await Repository(inst.db).contestRepository.findById(
        example.contestId,
      ))!;

      await expectLater(
        repo.appendWithContest(
          next,
          contest: core.Contest.fromJson({
            ...stale.toJson(),
            'revision': stale.revision + 5,
          }),
          metadata: metadata(),
          audit: audit(next.id),
        ),
        throwsA(isA<core.StaleRevisionError>()),
      );
      expect(await Repository(inst.db).auditEventRepository.listForContest(
        example.contestId,
        action: core.AuditAction.configurationSaved,
      ), isEmpty);
      expect(await repo.findById(next.id), isNull);
    });

    test('listForContest returns the revisions oldest first', () async {
      final third = await repo.append(revision(4), metadata: metadata());
      final first = await repo.append(revision(1), metadata: metadata());

      expect(await repo.listForContest(example.contestId), [
        first,
        example,
        third,
      ]);
    });

    test('latestForContest returns the highest revision number', () async {
      final newest = await repo.append(revision(7), metadata: metadata());
      await repo.append(revision(5), metadata: metadata());

      expect(await repo.latestForContest(example.contestId), newest);
    });

    test('a contest without revisions has none', () async {
      final other = core.Id.create();

      expect(await repo.listForContest(other), isEmpty);
      expect(await repo.latestForContest(other), isNull);
    });
  });
}
