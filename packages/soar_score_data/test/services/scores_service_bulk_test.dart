import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/drawn_contest.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

/// Bulk entry of scores against the real repositories, on SQLite and
/// PostgreSQL: one transaction, per-entry refusals, replays and the contest
/// start.
void _tests(Backend backend) {
  group('ScoresService bulk entry', () {
    late Installation inst;
    late Repository repository;
    late ScoresService service;
    late core.Id contestId;
    late List<core.Id> slots;
    final actor = core.Id.create();

    setUp(() async {
      inst = await Installation.open(backend);
      await SystemDataSeeder(inst.db).seed();
      repository = Repository(inst.db);
      service = ScoresService(repository);
      contestId = await drawnContest(repository, actor);
      final matrix = await MatrixService(repository).current(contestId);
      final first = matrix.rounds.firstWhere((round) => round.ordinal == 1);
      slots = [
        for (final assignment in matrix.assignments)
          if (assignment.scheduledRoundId == first.id) assignment.id,
      ];
    });

    tearDown(() => inst.close());

    var mutations = 0;
    core.MutationMetadata meta() => core.MutationMetadata(
      clientMutationId: 'request-${mutations++}',
      authority: core.Authority.director,
      clientTime: DateTime.utc(2026, 10, 8),
      actorId: actor,
    );

    Future<ScoreEntryResult> enter(
      core.Id assignmentId, {
      String mutation = 'entry-1',
    }) => service.enterOfficialScore(
      contestId,
      assignmentId,
      clientMutationId: mutation,
      baseScoreRevision: 0,
      components: const {
        'time_flown': 540,
        'launch_height': 200,
        'landing': 'points_50',
      },
      actorId: actor,
      metadata: meta(),
    );

    group('entering many scores at once', () {
      BulkScoreEntry bulkEntry(
        core.Id slot,
        String mutation, {
        int base = 0,
        String? reason,
      }) => BulkScoreEntry(
        assignmentId: slot,
        clientMutationId: mutation,
        baseScoreRevision: base,
        components: const {
          'time_flown': 540,
          'launch_height': 200,
          'landing': 'points_50',
        },
        reason: reason,
      );

      Future<List<BulkScoreOutcome>> enterMany(List<BulkScoreEntry> entries) =>
          service.enterOfficialScores(
            contestId,
            entries,
            actorId: actor,
            metadata: meta(),
          );

      test('stores every entry and starts the contest once', () async {
        final outcomes = await enterMany([
          for (final (i, slot) in slots.take(3).indexed)
            bulkEntry(slot, 'bulk-$i'),
        ]);

        expect(outcomes.every((o) => o.isSaved), isTrue);
        for (final outcome in outcomes) {
          expect(outcome.result!.officialScore.scoreRevision, 1);
          expect(outcome.result!.calculated.rawScore, 490);
          expect(
            outcome.result!.contest.lifecycleState,
            core.LifecycleState.running,
          );
        }
        expect(
          (await repository.contestRepository.findById(contestId))!
              .lifecycleState,
          core.LifecycleState.running,
        );
      });

      test('refuses a stale entry alone and keeps the others', () async {
        await enter(slots[0], mutation: 'single');

        final outcomes = await enterMany([
          bulkEntry(slots[0], 'bulk-0'),
          bulkEntry(slots[1], 'bulk-1'),
        ]);

        expect(outcomes[0].isSaved, isFalse);
        expect(outcomes[0].code, 'stale_revision');
        expect(outcomes[1].isSaved, isTrue);
      });

      test('a correction is audited like a single one', () async {
        await enter(slots[0], mutation: 'single');

        final outcomes = await enterMany([
          bulkEntry(slots[0], 'bulk-0', base: 1, reason: 'fixed'),
          bulkEntry(slots[1], 'bulk-1'),
        ]);

        expect(outcomes.every((o) => o.isSaved), isTrue);
        expect(outcomes[0].result!.officialScore.scoreRevision, 2);
        expect(outcomes[0].result!.officialScore.reason, 'fixed');
      });

      test('a repeated request replays and stores nothing more', () async {
        final entries = [
          bulkEntry(slots[0], 'bulk-0'),
          bulkEntry(slots[1], 'bulk-1'),
        ];
        final first = await enterMany(entries);

        final again = await enterMany(entries);

        expect(
          [for (final o in again) o.result!.officialScore],
          [for (final o in first) o.result!.officialScore],
        );
        expect(
          await repository.officialScoreRepository.listForPlaceholder(
            first[0].result!.placeholder.id,
          ),
          hasLength(1),
        );
      });

      test(
        'one mutation id used twice is refused, not a failed request',
        () async {
          final outcomes = await enterMany([
            bulkEntry(slots[0], 'same'),
            bulkEntry(slots[1], 'same'),
          ]);

          expect(outcomes[0].isSaved, isTrue);
          expect(outcomes[1].statusCode, 400);
          expect(outcomes[1].code, 'invalid_request');
        },
      );

      test(
        'a refused first entry does not stop the contest starting',
        () async {
          final outcomes = await enterMany([
            BulkScoreEntry(
              assignmentId: slots[0],
              clientMutationId: 'bad',
              baseScoreRevision: 0,
              components: const {'time_flown': -1},
            ),
            bulkEntry(slots[1], 'good'),
          ]);

          expect(outcomes[0].isSaved, isFalse);
          expect(outcomes[1].isSaved, isTrue);
          expect(
            outcomes[1].result!.contest.lifecycleState,
            core.LifecycleState.running,
          );
          expect(
            (await repository.contestRepository.findById(contestId))!
                .lifecycleState,
            core.LifecycleState.running,
          );
        },
      );

      test(
        'a replay mixed with a new entry reports the running contest',
        () async {
          final first = await enterMany([bulkEntry(slots[0], 'bulk-0')]);

          final again = await enterMany([
            bulkEntry(slots[1], 'bulk-1'),
            bulkEntry(slots[0], 'bulk-0'),
          ]);

          expect(again.every((o) => o.isSaved), isTrue);
          expect([
            for (final o in again) o.result!.contest.lifecycleState,
          ], everyElement(core.LifecycleState.running));
          expect(
            again[1].result!.officialScore,
            first.single.result!.officialScore,
          );
          expect(again[0].result!.officialScore.scoreRevision, 1);
        },
      );

      test('a repeat starts a contest an earlier request left Ready', () async {
        final first = await enterMany([bulkEntry(slots[0], 'bulk-0')]);
        // The earlier request stored its score but stopped before the start.
        final running = (await repository.contestRepository.findById(
          contestId,
        ))!;
        await repository.contestRepository.save(
          running.copyWithState(
            lifecycleState: core.LifecycleState.ready,
            updatedAt: DateTime.utc(2026, 10, 9),
          ),
          metadata: meta(),
        );

        final again = await enterMany([bulkEntry(slots[0], 'bulk-0')]);

        expect(
          again.single.result!.officialScore,
          first.single.result!.officialScore,
        );
        expect(
          again.single.result!.contest.lifecycleState,
          core.LifecycleState.running,
        );
      });

      test('a second entry for one slot is refused', () async {
        final outcomes = await enterMany([
          bulkEntry(slots[0], 'bulk-0'),
          bulkEntry(slots[0], 'bulk-1'),
        ]);

        expect(outcomes[0].isSaved, isTrue);
        expect(outcomes[1].statusCode, 400);
      });
    });
  });
}
