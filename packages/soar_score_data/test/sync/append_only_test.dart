import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import 'package:soar_score_data/soar_score_data.dart';

import '../support/backends.dart';
import '../support/example_entities.dart';
import '../support/example_rows.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    await loadExamples(inst);
  });
  tearDown(() => inst.close());

  core.ScoreAttempt newAttempt({String clientMutationId = 'attempt-new'}) =>
      core.ScoreAttempt.fromJson({
        ...exampleRows('score_attempt').first,
        'id': core.Id.create().value,
        'client_mutation_id': clientMutationId,
      });

  Future<int> mutationCount() => inst.count('mutation_records');

  group('append', () {
    test('stores a new entity and records one mutation', () async {
      final before = await mutationCount();
      final attempt = newAttempt();

      await inst.unitOfWork.run((c) => c.append(attempt, metadata: metadata()));

      final back = await inst.stores.of('ScoreAttempt').find(attempt.id);
      expect(back, equals(attempt));
      expect(await mutationCount(), before + 1);
      final row = await inst.db
          .customSelect(
            "SELECT entity_type, base_revision, outcome FROM mutation_records "
            "WHERE entity_id = '${attempt.id.value}'",
          )
          .getSingle();
      expect(row.read<String>('entity_type'), 'ScoreAttempt');
      expect(row.read<int?>('base_revision'), isNull);
      // This database has the server profile, where a direct write is
      // already accepted and takes the scope's next sequence.
      expect(row.read<String>('outcome'), 'Accepted');
    });

    test('refuses a second write of the same id and keeps nothing', () async {
      final attempt = newAttempt();
      await inst.unitOfWork.run((c) => c.append(attempt, metadata: metadata()));
      final before = await mutationCount();

      await expectLater(
        inst.unitOfWork.run(
          (c) => c.append(
            core.ScoreAttempt.fromJson({
              ...attempt.toJson(),
              'source_device': 'another-device',
            }),
            metadata: metadata(),
          ),
        ),
        throwsA(isA<core.AlreadyStoredError>()),
      );

      expect(await inst.stores.of('ScoreAttempt').find(attempt.id), attempt);
      expect(await mutationCount(), before);
    });

    test('refuses a reused client mutation id', () async {
      await inst.unitOfWork.run(
        (c) => c.append(newAttempt(), metadata: metadata()),
      );

      await expectLater(
        inst.unitOfWork.run(
          (c) => c.append(newAttempt(), metadata: metadata()),
        ),
        throwsA(anything),
      );
    });

    test('stores an official score', () async {
      final official = core.OfficialScore.fromJson({
        ...exampleRows('official_score').first,
        'id': core.Id.create().value,
        'score_revision': 99,
      });

      await inst.unitOfWork.run(
        (c) => c.append(official, metadata: metadata()),
      );

      expect(await inst.stores.of('OfficialScore').find(official.id), official);
    });

    test('stores a contest configuration revision', () async {
      final revision = core.ContestConfigurationRevision.fromJson({
        ...exampleRows('contest_configuration_revision').first,
        'id': core.Id.create().value,
        'revision_number': 99,
      });

      await inst.unitOfWork.run(
        (c) => c.append(revision, metadata: metadata()),
      );

      expect(
        await inst.stores.of('ContestConfigurationRevision').find(revision.id),
        revision,
      );
    });
  });
}
