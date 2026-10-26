import 'dart:convert';

import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/drawn_contest.dart';
import '../support/fixtures.dart';
import '../support/matrix_slot.dart';

void main() => forPostgresOnly(_tests);

/// The projection builder (hosted server only: publication data is backend
/// only) against the real repositories: what the public
/// snapshot holds, what it leaves out, and when it refuses to build.
void _tests(Backend backend) {
  group('PublicationProjectionBuilder', () {
    late Installation inst;
    late Repository repository;
    late ResultsService results;
    late PublicationProjectionBuilder builder;
    late core.Id contestId;
    late List<MatrixSlot> firstRound;
    final actor = core.Id.create();
    final publicationId = core.Id.create();
    var now = DateTime.utc(2026, 10, 17, 15);
    var keys = 0;

    setUp(() async {
      inst = await Installation.open(backend, profile: DatabaseProfile.server);
      await SystemDataSeeder(inst.db).seed();
      repository = Repository(inst.db);
      now = DateTime.utc(2026, 10, 17, 15);
      keys = 0;
      results = ResultsService(repository, clock: () => now);
      builder = PublicationProjectionBuilder(
        repository,
        results: results,
        clock: () => now,
        newPilotKey: () => 'key-${keys++}',
      );
      contestId = await drawnContest(repository, actor);
      await repository.publicationIdentityRepository.save(
        core.PublicationIdentity(
          id: publicationId,
          contestId: contestId,
          verificationEmail: 'director@example.com',
        ),
      );
      final matrix = await MatrixService(repository).current(contestId);
      final first = matrix.rounds.firstWhere((round) => round.ordinal == 1);
      firstRound = [
        for (final assignment in matrix.assignments)
          if (assignment.scheduledRoundId == first.id)
            MatrixSlot(assignment.id, assignment.contestParticipationId),
      ];
    });

    tearDown(() => inst.close());

    var mutations = 0;
    Future<void> enter(MatrixSlot slot, int seconds) =>
        ScoresService(repository, clock: () => now).enterOfficialScore(
          contestId,
          slot.assignmentId,
          clientMutationId: 'entry-${mutations++}',
          baseScoreRevision: 0,
          components: {
            'time_flown': seconds,
            'launch_height': 200,
            'landing': 'points_50',
          },
          actorId: actor,
          metadata: core.MutationMetadata(
            clientMutationId: 'meta-${mutations++}',
            authority: core.Authority.director,
            clientTime: now,
            actorId: actor,
          ),
        );

    Future<void> scoreAndCalculate() async {
      const times = [500, 540, 580, 590];
      for (var i = 0; i < firstRound.length; i++) {
        await enter(firstRound[i], times[i]);
      }
      await results.recalculate(contestId);
    }

    Future<PublicationBuild> build({int revision = 1, String id = 'm-1'}) =>
        builder.build(
          contestId: contestId,
          publicationId: publicationId,
          projectionRevision: revision,
          clientMutationId: id,
          publishedBy: actor,
        );

    test('a scored contest becomes a projection of its results', () async {
      await scoreAndCalculate();

      final built = await build();
      final projection = built.projection;

      expect(projection.projectionRevision, 1);
      expect(projection.publicationId, publicationId);
      expect(projection.publishedBy, actor);
      expect(projection.clientMutationId, 'm-1');
      expect(projection.disciplineType, core.DisciplineType.f5j);
      expect(projection.calculationVersion, 'f5j-1');
      expect(projection.configRevision, 1);
      expect(projection.contestIdentity['name'], 'Spring Open');
      expect(projection.contestIdentity['timezone'], 'America/Denver');
      expect(projection.participants, hasLength(4));
      expect(projection.scores, hasLength(4));
      final standings = projection.standings!['rounds']! as List<Object?>;
      expect(standings, hasLength(1));
      final pilots =
          (standings.single! as Map<String, Object?>)['pilots']!
              as List<Object?>;
      expect([for (final p in pilots) (p! as Map)['place']], [1, 2, 3, 4]);
    });

    test('each score carries the raw components the site labels', () async {
      await scoreAndCalculate();

      final projection = (await build()).projection;

      final times = [
        for (final score in projection.scores!)
          ((score! as Map)['raw_components']! as Map)['time_flown'],
      ];
      expect(times, unorderedEquals([500, 540, 580, 590]));
      for (final score in projection.scores!) {
        // The landing is an id into a table; its points are already in the
        // entry.
        expect(
          (score! as Map)['raw_components'],
          allOf(containsPair('launch_height', 200), isNot(contains('landing'))),
        );
      }
      final fields =
          projection.calculationMetadata!['score_fields']! as List<Object?>;
      final keys = [for (final f in fields) (f! as Map)['key']];
      expect(keys, containsAll(['time_flown', 'launch_height']));
      expect(keys, isNot(contains('landing')));
      expect((fields.first! as Map).keys, containsAll(['name', 'type']));
    });

    test('pilots are keyed and their details go to participant rows', () async {
      await scoreAndCalculate();

      final built = await build();

      expect(built.participants, hasLength(4));
      expect(
        {for (final p in built.participants) p.pilotKey},
        {'key-0', 'key-1', 'key-2', 'key-3'},
      );
      expect(
        {for (final p in built.participants) p.details!['last_name']},
        {'Test'},
      );
      expect(
        {for (final p in built.participants) p.details!['club']},
        {'Club0', 'Club1', 'Club2', 'Club3'},
      );
    });

    test('the projection holds no private or identifying data', () async {
      await scoreAndCalculate();

      final text = jsonEncode((await build()).projection.toJson());

      for (final secret in [
        'example.com',
        'FAI-',
        'Pilot0',
        'Test',
        'Club',
        'email',
        actor.value,
        for (final slot in firstRound) slot.participationId.value,
        for (final slot in firstRound) slot.assignmentId.value,
      ]) {
        // The publisher's account id is the one allowed reference.
        if (secret == actor.value) continue;
        expect(text, isNot(contains(secret)), reason: secret);
      }
    });

    test('a pilot keeps the same key across publishes', () async {
      await scoreAndCalculate();
      final first = await build();
      for (final row in first.participants) {
        await repository.publicationParticipantRepository.save(row);
      }

      final second = await build(revision: 2, id: 'm-2');

      expect(second.participants, isEmpty);
      expect(
        {
          for (final p in second.projection.participants!)
            (p! as Map)['pilot_key'],
        },
        {for (final p in first.participants) p.pilotKey},
      );
      expect(keys, 4);
    });

    test(
      'changed details are refreshed and redacted rows left alone',
      () async {
        await scoreAndCalculate();
        final first = await build();
        for (final row in first.participants) {
          await repository.publicationParticipantRepository.save(row);
        }
        final redacted = first.participants.first;
        await repository.publicationParticipantRepository.save(
          core.PublicationParticipant(
            id: redacted.id,
            publicationId: redacted.publicationId,
            pilotKey: redacted.pilotKey,
            sourceParticipationId: redacted.sourceParticipationId,
            redactedAt: now,
            createdAt: redacted.createdAt,
            updatedAt: now,
          ),
        );
        final other = first.participants[1];
        final participation = await repository.contestParticipationRepository
            .findById(other.sourceParticipationId!);
        final profile = (await repository.participantProfileRepository.findById(
          participation!.participantProfileId,
        ))!;
        await ParticipantsService(repository).update(
          actor,
          profile.id,
          ParticipantDetails(
            firstName: profile.firstName,
            lastName: 'Renamed',
            club: profile.club,
          ),
          baseRevision: profile.revision,
          metadata: core.MutationMetadata(
            clientMutationId: 'rename',
            authority: core.Authority.director,
            clientTime: now,
            actorId: actor,
          ),
        );
        now = now.add(const Duration(minutes: 1));

        final second = await build(revision: 2, id: 'm-2');

        expect(second.participants, hasLength(1));
        expect(second.participants.single.id, other.id);
        expect(second.participants.single.pilotKey, other.pilotKey);
        expect(second.participants.single.details!['last_name'], 'Renamed');
      },
    );

    test('stale results are refused', () async {
      await scoreAndCalculate();
      now = now.add(const Duration(minutes: 5));
      await ScoresService(repository, clock: () => now).enterOfficialScore(
        contestId,
        firstRound[0].assignmentId,
        clientMutationId: 'late',
        baseScoreRevision: 1,
        components: {
          'time_flown': 595,
          'launch_height': 200,
          'landing': 'points_50',
        },
        reason: 'Timer misread',
        actorId: actor,
        metadata: core.MutationMetadata(
          clientMutationId: 'late-meta',
          authority: core.Authority.director,
          clientTime: now,
          actorId: actor,
        ),
      );

      await expectLater(
        build(),
        throwsA(
          isA<core.ContestStateError>().having(
            (e) => e.code,
            'code',
            'results_stale',
          ),
        ),
      );
    });

    test('a contest with no scores yet still builds', () async {
      final built = await build();

      expect(built.projection.scores, isEmpty);
      expect(
        (built.projection.standings!['rounds']! as List<Object?>),
        isEmpty,
      );
      expect(built.projection.participants, hasLength(4));
    });

    test('a contest without a matrix is refused', () async {
      final empty = core.Id.create();
      await ContestsService(repository).createContest(
        NewContest(
          id: empty,
          timezone: 'America/Denver',
          details: ContestDetails(
            name: 'Empty',
            startDateTime: DateTime.utc(2026, 10, 17, 14),
            endDateTime: DateTime.utc(2026, 10, 18, 22),
          ),
        ),
        ownerAccountId: actor,
        metadata: core.MutationMetadata(
          clientMutationId: 'empty',
          authority: core.Authority.director,
          clientTime: now,
          actorId: actor,
        ),
      );

      await expectLater(
        builder.build(
          contestId: empty,
          publicationId: publicationId,
          projectionRevision: 1,
          clientMutationId: 'x',
        ),
        throwsA(
          isA<core.ContestStateError>().having(
            (e) => e.code,
            'code',
            'nothing_to_publish',
          ),
        ),
      );
    });

    test('a contest that does not exist is refused', () async {
      await expectLater(
        builder.build(
          contestId: core.Id.create(),
          publicationId: publicationId,
          projectionRevision: 1,
          clientMutationId: 'x',
        ),
        throwsA(isA<core.EntityNotFoundError>()),
      );
    });
  });
}
