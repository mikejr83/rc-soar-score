import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/example_entities.dart';
import '../support/example_rows.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

const _round81 = '019c0000-0000-7000-8000-000000000081';
const _round82 = '019c0000-0000-7000-8000-000000000082';

void _tests(Backend backend) {
  late Installation inst;
  late Repository repository;

  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    await loadExamples(inst);
    repository = Repository(inst.db);
  });
  tearDown(() => inst.close());

  Future<int> tombstones() => inst.count('tombstones');

  final rounds = [
    for (final row in exampleRows('round')) core.Round.fromJson(row),
  ];
  final groups = [
    for (final row in exampleRows('round_group')) core.RoundGroup.fromJson(row),
  ];
  final assignments = [
    for (final row in exampleRows('matrix_assignment'))
      core.MatrixAssignment.fromJson(row),
  ];

  group('RoundRepository', () {
    late core.RoundRepository repo;
    setUp(() => repo = repository.roundRepository);

    test('reads back the example rounds unchanged', () async {
      for (final round in rounds) {
        expect(await repo.findById(round.id), round);
      }
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('lists rounds by ordinal', () async {
      expect(await repo.listForRevision(rounds.first.matrixRevisionId), rounds);
      expect(await repo.listForContest(rounds.first.contestId), rounds);
      expect(await repo.listForContest(core.Id.create()), isEmpty);
    });

    test('save updates the round and bumps the revision', () async {
      final changed = core.Round.fromJson({
        ...rounds.first.toJson(),
        'group_count': rounds.first.groupCount + 1,
      });

      final saved = await repo.save(changed, metadata: metadata());

      expect(saved.revision, rounds.first.revision + 1);
      expect(
        (await repo.findById(saved.id))?.groupCount,
        rounds.first.groupCount + 1,
      );
    });

    test('save refuses a round read at an older revision', () async {
      final stale = core.Round.fromJson({
        ...rounds.first.toJson(),
        'revision': 0,
      });

      expect(
        repo.save(stale, metadata: metadata()),
        throwsA(isA<core.StaleRevisionError>()),
      );
    });

    test('delete removes an unused round and its groups together', () async {
      final fresh = await repo.save(
        core.Round.fromJson({
          ...rounds.first.toJson(),
          'id': core.Id.create().value,
          'ordinal': 9,
          'revision': 0,
        }),
        metadata: metadata(),
      );
      for (final number in [1, 2]) {
        await repository.roundGroupRepository.save(
          core.RoundGroup.fromJson({
            ...groups.first.toJson(),
            'id': core.Id.create().value,
            'round_id': fresh.id.value,
            'group_number': number,
            'revision': 0,
          }),
          metadata: metadata(),
        );
      }
      final before = await tombstones();

      expect(await repo.delete(fresh.id, metadata: metadata()), isTrue);

      expect(await repo.findById(fresh.id), isNull);
      expect(
        await repository.roundGroupRepository.listForRound(fresh.id),
        isEmpty,
      );
      expect(await tombstones(), before + 3);
      expect(await repo.delete(fresh.id, metadata: metadata()), isFalse);
    });

    test('delete refuses a round that assignments refer to', () async {
      await expectLater(
        repo.delete(rounds.first.id, metadata: metadata()),
        throwsA(anything),
      );
      expect(await repo.findById(rounds.first.id), isNotNull);
    });
  });

  group('RoundGroupRepository', () {
    late core.RoundGroupRepository repo;
    setUp(() => repo = repository.roundGroupRepository);

    test('reads back the example groups unchanged', () async {
      for (final group in groups) {
        expect(await repo.findById(group.id), group);
      }
    });

    test('lists groups of a round by group number', () async {
      final ofRound82 = groups.where((g) => g.roundId.value == _round82);

      expect(
        await repo.listForRound(core.Id.parse(_round82)),
        orderedEquals(ofRound82),
      );
      expect(
        await repo.listForContest(groups.first.contestId),
        hasLength(groups.length),
      );
    });

    test('save then delete a group', () async {
      final fresh = core.RoundGroup.fromJson({
        ...groups.first.toJson(),
        'id': core.Id.create().value,
        'group_number': 9,
        'revision': 0,
      });

      expect(await repo.save(fresh, metadata: metadata()), fresh);
      expect(await repo.findById(fresh.id), fresh);

      expect(await repo.delete(fresh.id, metadata: metadata()), isTrue);
      expect(await repo.findById(fresh.id), isNull);
      expect(await repo.delete(fresh.id, metadata: metadata()), isFalse);
    });
  });

  group('MatrixAssignmentRepository', () {
    late core.MatrixAssignmentRepository repo;
    setUp(() => repo = repository.matrixAssignmentRepository);

    core.MatrixAssignment moveOf(core.MatrixAssignment from) =>
        core.MatrixAssignment.fromJson({
          ...from.toJson(),
          'id': core.Id.create().value,
          'scheduled_round_id': _round82,
          'group': 2,
          'assignment_type': 'Moved',
          'source_assignment_id': from.id.value,
          'reason': 'Moved to the later round',
          'created_at': '2026-10-17T16:00:00Z',
        });

    core.ScorePlaceholder placeholderOf(core.MatrixAssignment moved) =>
        core.ScorePlaceholder(
          id: core.Id.create(),
          contestId: moved.contestId,
          contestParticipationId: moved.contestParticipationId,
          assignmentId: moved.id,
        );

    test('reads back the example assignments unchanged', () async {
      for (final assignment in assignments) {
        expect(await repo.findById(assignment.id), assignment);
      }
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('lists by revision and by participation', () async {
      final revisionId = assignments.first.matrixRevisionId;
      final participationId = assignments.first.contestParticipationId;

      expect(
        await repo.listForRevision(revisionId),
        unorderedEquals(assignments),
      );
      expect(
        await repo.listForParticipation(participationId),
        unorderedEquals(
          assignments.where((a) => a.contestParticipationId == participationId),
        ),
      );
    });

    test('append refuses an id that is already stored', () async {
      expect(
        repo.append(assignments.first, metadata: metadata()),
        throwsA(isA<core.AlreadyStoredError>()),
      );
    });

    test('move stores the new row and marks the old one', () async {
      final source = assignments.first;
      final moved = moveOf(source);

      final placeholder = placeholderOf(moved);

      expect(
        await repo.move(moved, placeholder: placeholder, metadata: metadata()),
        moved,
      );
      expect(
        (await repository.scorePlaceholderRepository.findForAssignment(
          moved.id,
        ))?.id,
        placeholder.id,
      );

      expect(await repo.findById(moved.id), moved);
      expect(
        (await repo.findById(source.id))?.supersededByAssignmentId,
        moved.id,
      );
    });

    test('a second move of the same assignment is refused', () async {
      final source = assignments.first;
      final first = moveOf(source);
      await repo.move(
        first,
        placeholder: placeholderOf(first),
        metadata: metadata(),
      );

      final second = moveOf(source);
      expect(
        repo.move(
          second,
          placeholder: placeholderOf(second),
          metadata: metadata(),
        ),
        throwsA(isA<core.AlreadySupersededError>()),
      );
    });

    test('listLiveForRound leaves out replaced assignments', () async {
      final source = assignments.first;
      final before = await repo.listLiveForRound(core.Id.parse(_round81));
      expect(before, contains(source));

      final moved = moveOf(source);
      await repo.move(
        moved,
        placeholder: placeholderOf(moved),
        metadata: metadata(),
      );

      final after = await repo.listLiveForRound(core.Id.parse(_round81));
      expect(after.map((a) => a.id), isNot(contains(source.id)));
      expect(after, hasLength(before.length - 1));
      expect(
        (await repo.listLiveForRound(core.Id.parse(_round82))).map((a) => a.id),
        contains(moved.id),
      );
    });
  });
}
