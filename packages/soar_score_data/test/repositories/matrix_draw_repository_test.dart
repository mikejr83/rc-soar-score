import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/example_entities.dart';
import '../support/example_rows.dart';
import '../support/fixtures.dart';

void main() {
  forEachBackend(_tests);
  _drawTests();
}

void _tests(Backend backend) {
  group('MatrixRevisionRepository', () {
    late Installation inst;
    late Repository repository;
    late core.MatrixRevisionRepository repo;

    setUp(() async {
      inst = await Installation.open(backend, profile: DatabaseProfile.server);
      await loadExamples(inst);
      repository = Repository(inst.db);
      repo = repository.matrixRevisionRepository;
    });
    tearDown(() => inst.close());

    final example = core.MatrixRevision.fromJson(
      exampleRows('matrix_revision').single,
    );

    /// A second revision with one new round, group and assignment.
    core.MatrixDraw newDraw({String? assignmentId, int ordinal = 3}) {
      final revision = core.MatrixRevision.fromJson({
        ...exampleRows('matrix_revision').single,
        'id': core.Id.create().value,
        'revision_number': 2,
        'previous_revision_id': example.id.value,
        'first_round': ordinal,
        'last_round': ordinal,
        'finalized_by': null,
        'finalized_at': null,
      });
      final round = core.Round.fromJson({
        ...exampleRows('round').first,
        'id': core.Id.create().value,
        'matrix_revision_id': revision.id.value,
        'ordinal': ordinal,
        'revision': 0,
      });
      final group = core.RoundGroup.fromJson({
        ...exampleRows('round_group').first,
        'id': core.Id.create().value,
        'round_id': round.id.value,
        'revision': 0,
      });
      final entry = core.MatrixAssignment.fromJson({
        ...exampleRows('matrix_assignment').first,
        'id': assignmentId ?? core.Id.create().value,
        'matrix_revision_id': revision.id.value,
        'scheduled_round_id': round.id.value,
        'credited_round_id': round.id.value,
      });
      return core.MatrixDraw(
        revision: revision,
        rounds: [round],
        groups: [group],
        assignments: [entry],
      );
    }

    test('reads back the example revision unchanged', () async {
      expect(await repo.findById(example.id), example);
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('appendDraw stores the whole draw, one mutation per row', () async {
      final before = await inst.count('mutation_records');
      final draw = newDraw();

      await repo.appendDraw(draw, metadata: metadata());

      expect(await repo.findById(draw.revision.id), draw.revision);
      expect(
        await repository.roundRepository.listForRevision(draw.revision.id),
        draw.rounds,
      );
      expect(
        await repository.roundGroupRepository.listForRound(
          draw.rounds.single.id,
        ),
        draw.groups,
      );
      expect(
        await repository.matrixAssignmentRepository.listForRevision(
          draw.revision.id,
        ),
        draw.assignments,
      );
      expect(await inst.count('mutation_records'), before + 4);
    });

    test('appendDraw stores nothing when one row is refused', () async {
      final draw = newDraw(
        assignmentId: exampleRows('matrix_assignment').first['id'] as String,
      );

      await expectLater(
        repo.appendDraw(draw, metadata: metadata()),
        throwsA(anything),
      );

      expect(await repo.findById(draw.revision.id), isNull);
      expect(
        await repository.roundRepository.listForRevision(draw.revision.id),
        isEmpty,
      );
    });

    /// [newDraw] finalized: a placeholder for its assignment, a participant
    /// number for the assigned participation, and the contest made Ready.
    Future<core.FinalizedDraw> newFinalized({String? placeholderId}) async {
      final draw = newDraw();
      final assignment = draw.assignments.single;
      final participation = (await repository.contestParticipationRepository
          .findById(assignment.contestParticipationId))!;
      final contest = (await repository.contestRepository.findById(
        example.contestId,
      ))!;
      return core.FinalizedDraw(
        draw: draw,
        placeholders: [
          core.ScorePlaceholder(
            id: core.Id.parse(placeholderId ?? core.Id.create().value),
            contestId: example.contestId,
            contestParticipationId: participation.id,
            assignmentId: assignment.id,
          ),
        ],
        numberedParticipations: [participation.withParticipantNumber(99)],
        contest: contest.copyWithState(
          lifecycleState: core.LifecycleState.ready,
          updatedAt: DateTime.utc(2026, 5, 1, 12),
        ),
      );
    }

    test('appendFinalizedDraw stores the draw, placeholders, participant '
        'numbers and the Ready contest together', () async {
      final finalized = await newFinalized();
      final before = await inst.count('mutation_records');

      await repo.appendFinalizedDraw(finalized, metadata: metadata());

      final assignment = finalized.draw.assignments.single;
      expect(
        await repo.findById(finalized.draw.revision.id),
        finalized.draw.revision,
      );
      expect(
        (await repository.scorePlaceholderRepository.findForAssignment(
          assignment.id,
        ))!.contestParticipationId,
        assignment.contestParticipationId,
      );
      expect(
        (await repository.contestParticipationRepository.findById(
          assignment.contestParticipationId,
        ))!.participantNumber,
        99,
      );
      expect(
        (await repository.contestRepository.findById(example.contestId))!
            .lifecycleState,
        core.LifecycleState.ready,
      );
      // Revision, round, group, assignment, placeholder, participation and
      // contest.
      expect(await inst.count('mutation_records'), before + 7);
    });

    test('appendRedraw supersedes a round and stores the new one in its '
        'place', () async {
      final replaced = (await repository.roundRepository.listForContest(
        example.contestId,
      )).firstWhere((round) => round.ordinal == 2);
      final draw = newDraw(ordinal: 2);
      final assignment = draw.assignments.single;
      final participation = (await repository.contestParticipationRepository
          .findById(assignment.contestParticipationId))!;
      final redraw = core.FinalizedRedraw(
        draw: draw,
        placeholders: [
          core.ScorePlaceholder(
            id: core.Id.create(),
            contestId: example.contestId,
            contestParticipationId: participation.id,
            assignmentId: assignment.id,
          ),
        ],
        numberedParticipations: [participation.withParticipantNumber(99)],
        replacedRounds: [
          core.Round.fromJson({
            ...replaced.toJson(),
            'superseded_by_round_id': draw.rounds.single.id.value,
          }),
        ],
      );

      await repo.appendRedraw(redraw, metadata: metadata());

      final rounds = await repository.roundRepository.listForContest(
        example.contestId,
      );
      final live = rounds.where((round) => round.isCurrent).toList();
      expect(
        live.where((round) => round.ordinal == 2).single.id,
        draw.rounds.single.id,
      );
      expect(
        rounds.firstWhere((round) => round.id == replaced.id).isSuperseded,
        isTrue,
      );
      expect(await repo.findById(draw.revision.id), draw.revision);
      expect(
        (await repository.scorePlaceholderRepository.findForAssignment(
          assignment.id,
        )),
        isNotNull,
      );
    });

    test('appendRedraw cancels a round the redraw does not reach', () async {
      final replaced = (await repository.roundRepository.listForContest(
        example.contestId,
      )).firstWhere((round) => round.ordinal == 2);
      final draw = newDraw(ordinal: 3);
      final assignment = draw.assignments.single;
      final redraw = core.FinalizedRedraw(
        draw: draw,
        placeholders: [
          core.ScorePlaceholder(
            id: core.Id.create(),
            contestId: example.contestId,
            contestParticipationId: assignment.contestParticipationId,
            assignmentId: assignment.id,
          ),
        ],
        numberedParticipations: const [],
        replacedRounds: [
          core.Round.fromJson({...replaced.toJson(), 'status': 'Cancelled'}),
        ],
      );

      await repo.appendRedraw(redraw, metadata: metadata());

      final stored = (await repository.roundRepository.findById(replaced.id))!;
      expect(stored.isCurrent, isFalse);
      expect(stored.status, core.RoundStatus.cancelled);
    });

    test('appendFinalizedDraw stores nothing when a placeholder is '
        'refused', () async {
      final taken = (await repository.scorePlaceholderRepository.listForContest(
        example.contestId,
      )).first;
      final finalized = await newFinalized(placeholderId: taken.id.value);

      await expectLater(
        repo.appendFinalizedDraw(finalized, metadata: metadata()),
        throwsA(anything),
      );

      expect(await repo.findById(finalized.draw.revision.id), isNull);
      expect(
        (await repository.contestParticipationRepository.findById(
          finalized.draw.assignments.single.contestParticipationId,
        ))!.participantNumber,
        isNot(99),
      );
    });

    test('listForContest and latestForContest order by number', () async {
      final draw = newDraw();
      await repo.appendDraw(draw, metadata: metadata());

      expect(await repo.listForContest(example.contestId), [
        example,
        draw.revision,
      ]);
      expect(await repo.latestForContest(example.contestId), draw.revision);
      expect(await repo.latestForContest(core.Id.create()), isNull);
    });
  });
}

void _drawTests() {
  group('MatrixDraw', () {
    final revision = core.MatrixRevision.fromJson(
      exampleRows('matrix_revision').single,
    );
    final round = core.Round.fromJson(exampleRows('round').first);

    test('refuses a round of another revision', () {
      final other = core.Round.fromJson({
        ...round.toJson(),
        'matrix_revision_id': core.Id.create().value,
      });

      expect(
        () => core.MatrixDraw(
          revision: revision,
          rounds: [other],
          groups: const [],
          assignments: const [],
        ),
        throwsArgumentError,
      );
    });

    test('refuses a group of a round that is not in the draw', () {
      final group = core.RoundGroup.fromJson(exampleRows('round_group').last);

      expect(
        () => core.MatrixDraw(
          revision: revision,
          rounds: [round],
          groups: [group],
          assignments: const [],
        ),
        throwsArgumentError,
      );
    });
  });
}
