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

  final placeholders = [
    for (final row in exampleRows('score_placeholder'))
      core.ScorePlaceholder.fromJson(row),
  ];
  final attempts = [
    for (final row in exampleRows('score_attempt'))
      core.ScoreAttempt.fromJson(row),
  ];
  final officials = [
    for (final row in exampleRows('official_score'))
      core.OfficialScore.fromJson(row),
  ];

  /// The placeholder no one has scored yet.
  final open = placeholders.firstWhere(
    (p) => p.state == core.ScorePlaceholderState.notEntered,
  );

  core.ScoreAttempt attemptAt(core.ScorePlaceholder placeholder) =>
      core.ScoreAttempt.fromJson({
        ...attempts.first.toJson(),
        'id': core.Id.create().value,
        'score_placeholder_id': placeholder.id.value,
        'client_mutation_id': 'attempt-${core.Id.create().value}',
        'base_score_revision': placeholder.scoreRevision,
      });

  core.ScorePlaceholder withState(
    core.ScorePlaceholder placeholder,
    String state, {
    int? scoreRevision,
  }) => core.ScorePlaceholder.fromJson({
    ...placeholder.toJson(),
    'state': state,
    'score_revision': ?scoreRevision,
  });

  group('ScorePlaceholderRepository', () {
    late core.ScorePlaceholderRepository repo;
    setUp(() => repo = repository.scorePlaceholderRepository);

    test('reads back the example placeholders unchanged', () async {
      for (final placeholder in placeholders) {
        expect(await repo.findById(placeholder.id), placeholder);
      }
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('finds the placeholder of an assignment', () async {
      final first = placeholders.first;

      expect(await repo.findForAssignment(first.assignmentId), first);
      expect(await repo.findForAssignment(core.Id.create()), isNull);
    });

    test('lists by contest and by participation', () async {
      final first = placeholders.first;

      expect(
        await repo.listForContest(first.contestId),
        unorderedEquals(placeholders),
      );
      expect(
        await repo.listForParticipation(first.contestParticipationId),
        unorderedEquals(
          placeholders.where(
            (p) => p.contestParticipationId == first.contestParticipationId,
          ),
        ),
      );
    });

    test('save bumps the revision and refuses a stale copy', () async {
      final saved = await repo.save(
        withState(open, 'Submitted'),
        metadata: metadata(),
      );

      expect(saved.revision, open.revision + 1);
      expect(
        repo.save(withState(open, 'InReview'), metadata: metadata()),
        throwsA(isA<core.StaleRevisionError>()),
      );
    });

    test('delete removes an unscored placeholder', () async {
      expect(await repo.delete(open.id, metadata: metadata()), isTrue);

      expect(await repo.findById(open.id), isNull);
      expect(await repo.delete(open.id, metadata: metadata()), isFalse);
    });

    test('delete refuses a placeholder that has attempts', () async {
      await expectLater(
        repo.delete(placeholders.first.id, metadata: metadata()),
        throwsA(anything),
      );
      expect(await repo.findById(placeholders.first.id), isNotNull);
    });
  });

  group('ScoreAttemptRepository', () {
    late core.ScoreAttemptRepository repo;
    setUp(() => repo = repository.scoreAttemptRepository);

    test('reads back the example attempts unchanged', () async {
      for (final attempt in attempts) {
        expect(await repo.findById(attempt.id), attempt);
      }
    });

    test('finds an attempt by its client mutation id', () async {
      final first = attempts.first;

      expect(
        await repo.findByClientMutationId(
          first.contestId,
          first.clientMutationId,
        ),
        first,
      );
      expect(
        await repo.findByClientMutationId(first.contestId, 'unknown'),
        isNull,
      );
    });

    test('append stores an attempt and refuses a stored id', () async {
      final attempt = attemptAt(open);

      expect(await repo.append(attempt, metadata: metadata()), attempt);
      expect(await repo.listForPlaceholder(open.id), [attempt]);
      expect(await repo.latestForPlaceholder(open.id), attempt);
      expect(
        repo.append(attempt, metadata: metadata()),
        throwsA(isA<core.AlreadyStoredError>()),
      );
    });

    test('latestForPlaceholder is null without attempts', () async {
      expect(await repo.latestForPlaceholder(open.id), isNull);
      expect(await repo.listForPlaceholder(open.id), isEmpty);
    });

    test('recordAttempt stores the attempt and the placeholder', () async {
      final before = await inst.count('mutation_records');
      final attempt = attemptAt(open);

      await repo.recordAttempt(
        attempt,
        withState(open, 'Submitted'),
        metadata: metadata(),
      );

      expect(await repo.findById(attempt.id), attempt);
      final stored = await repository.scorePlaceholderRepository.findById(
        open.id,
      );
      expect(stored?.state, core.ScorePlaceholderState.submitted);
      expect(await inst.count('mutation_records'), before + 2);
    });

    test(
      'recordAttempt stores neither when the placeholder is stale',
      () async {
        final attempt = attemptAt(open);
        final stale = core.ScorePlaceholder.fromJson({
          ...withState(open, 'Submitted').toJson(),
          'revision': open.revision + 5,
        });

        await expectLater(
          repo.recordAttempt(attempt, stale, metadata: metadata()),
          throwsA(isA<core.StaleRevisionError>()),
        );

        expect(await repo.findById(attempt.id), isNull);
      },
    );

    test('recordAttempt refuses another placeholder', () async {
      expect(
        () => repo.recordAttempt(
          attemptAt(open),
          placeholders.first,
          metadata: metadata(),
        ),
        throwsArgumentError,
      );
    });
  });

  group('OfficialScoreRepository', () {
    late core.OfficialScoreRepository repo;
    setUp(() => repo = repository.officialScoreRepository);

    core.OfficialScore officialFor(core.ScoreAttempt attempt, int revision) =>
        core.OfficialScore.fromJson({
          ...officials.first.toJson(),
          'id': core.Id.create().value,
          'score_placeholder_id': attempt.scorePlaceholderId.value,
          'score_attempt_id': attempt.id.value,
          'score_revision': revision,
        });

    test('reads back the example official scores unchanged', () async {
      for (final score in officials) {
        expect(await repo.findById(score.id), score);
      }
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('lists a placeholder scores by revision, newest is current', () async {
      final first = officials.first;
      final placeholder = placeholders.firstWhere(
        (p) => p.id == first.scorePlaceholderId,
      );
      final correction = await repo.append(
        officialFor(attempts.first, 2),
        metadata: metadata(),
      );

      expect(await repo.listForPlaceholder(placeholder.id), [
        first,
        correction,
      ]);
      expect(await repo.currentForPlaceholder(placeholder.id), correction);
      expect(await repo.currentForPlaceholder(open.id), isNull);
    });

    test('append refuses an id that is already stored', () async {
      expect(
        repo.append(officials.first, metadata: metadata()),
        throwsA(isA<core.AlreadyStoredError>()),
      );
    });

    test('recordOfficial stores the score and the placeholder', () async {
      final attempt = await repository.scoreAttemptRepository.append(
        attemptAt(open),
        metadata: metadata(),
      );
      final before = await inst.count('mutation_records');
      final official = officialFor(attempt, 1);

      await repo.recordOfficial(
        official,
        withState(open, 'Official', scoreRevision: 1),
        metadata: metadata(),
      );

      expect(await repo.currentForPlaceholder(open.id), official);
      final stored = await repository.scorePlaceholderRepository.findById(
        open.id,
      );
      expect(stored?.state, core.ScorePlaceholderState.official);
      expect(stored?.scoreRevision, 1);
      expect(await inst.count('mutation_records'), before + 2);
    });

    test('recordOfficial refuses a placeholder with another revision', () {
      expect(
        () => repo.recordOfficial(
          officialFor(attempts.first, 2),
          placeholders.first,
          metadata: metadata(),
        ),
        throwsArgumentError,
      );
    });

    test('recordOfficial refuses another placeholder', () async {
      final attempt = await repository.scoreAttemptRepository.append(
        attemptAt(open),
        metadata: metadata(),
      );

      expect(
        () => repo.recordOfficial(
          officialFor(attempt, 1),
          placeholders.first,
          metadata: metadata(),
        ),
        throwsArgumentError,
      );
    });
  });
}
