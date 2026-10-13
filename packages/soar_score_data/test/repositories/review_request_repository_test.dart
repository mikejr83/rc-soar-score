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
  late core.ReviewRequestRepository repo;

  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    await loadExamples(inst);
    repo = Repository(inst.db).reviewRequestRepository;
  });
  tearDown(() => inst.close());

  final examples = [
    for (final row in exampleRows('review_request'))
      core.ReviewRequest.fromJson(row),
  ];
  final first = examples.first;

  /// A new request for [first]'s score that is still waiting on a decision.
  core.ReviewRequest openRequest({String state = 'Submitted'}) =>
      core.ReviewRequest.fromJson({
        ...first.toJson(),
        'id': core.Id.create().value,
        'state': state,
        'decision_actor_id': null,
        'decision_time': null,
        'decision_message': null,
        'resulting_attempt_id': null,
        'revision': 0,
      });

  test('reads back every example request unchanged', () async {
    for (final request in examples) {
      expect(await repo.findById(request.id), request);
    }
    expect(await repo.findById(core.Id.create()), isNull);
  });

  test('lists by contest and by score', () async {
    expect(await repo.listForContest(first.contestId), examples);
    expect(await repo.listForContest(core.Id.create()), isEmpty);
    expect(await repo.listForScorePlaceholder(first.scorePlaceholderId), [
      first,
    ]);
    expect(await repo.listForScorePlaceholder(core.Id.create()), isEmpty);
  });

  test('finds the open request of a score', () async {
    expect(
      await repo.findOpenForScorePlaceholder(first.scorePlaceholderId),
      isNull,
    );
    expect(await repo.listOpenForContest(first.contestId), isEmpty);

    final open = await repo.save(openRequest(), metadata: metadata());

    expect(
      await repo.findOpenForScorePlaceholder(first.scorePlaceholderId),
      open,
    );
    expect(await repo.listOpenForContest(first.contestId), [open]);
  });

  test(
    'save stores a request, bumps the revision, refuses a stale one',
    () async {
      final saved = await repo.save(openRequest(), metadata: metadata());
      expect(await repo.findById(saved.id), saved);

      final underReview = core.ReviewRequest.fromJson({
        ...saved.toJson(),
        'state': 'UnderReview',
      });
      final updated = await repo.save(underReview, metadata: metadata());
      expect(updated.revision, saved.revision + 1);
      expect(updated.state, core.ReviewRequestState.underReview);

      await expectLater(
        repo.save(underReview, metadata: metadata()),
        throwsA(isA<core.StaleRevisionError>()),
      );
    },
  );

  test('save writes a mutation record', () async {
    final before = await inst.count('mutation_records');

    await repo.save(openRequest(), metadata: metadata());

    expect(await inst.count('mutation_records'), before + 1);
  });

  test('a score cannot have a second open request', () async {
    await repo.save(openRequest(), metadata: metadata());

    await expectLater(
      repo.save(openRequest(state: 'UnderReview'), metadata: metadata()),
      throwsA(anything),
    );
  });
}
