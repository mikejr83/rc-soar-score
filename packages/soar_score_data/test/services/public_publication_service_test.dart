import 'dart:convert';

import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/drawn_contest.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

/// What an anonymous reader gets from published contests, against the real
/// repositories: who can read what, and what never reaches the client.
void _tests(Backend backend) {
  group('PublicPublicationService', () {
    late Installation inst;
    late Repository repository;
    late PublicationService publishing;
    late PublicPublicationService reading;
    late core.Id contestId;
    final actor = core.Id.create();
    var now = DateTime.utc(2026, 10, 17, 15);

    setUp(() async {
      inst = await Installation.open(backend, profile: DatabaseProfile.server);
      await SystemDataSeeder(inst.db).seed();
      repository = Repository(inst.db);
      now = DateTime.utc(2026, 10, 17, 15);
      publishing = PublicationService(repository, clock: () => now);
      reading = PublicPublicationService(repository);
      await repository.accountRepository.save(
        core.Account(
          id: actor,
          firstName: 'Dana',
          lastName: 'Director',
          kind: core.AccountKind.registered,
          createdAt: now,
          updatedAt: now,
        ),
      );
      contestId = await drawnContest(repository, actor);
    });

    tearDown(() => inst.close());

    var mutations = 0;

    /// Scores every slot of every round, calculates, and returns nothing.
    Future<void> scoreEverything() async {
      final matrix = await MatrixService(repository).current(contestId);
      for (final assignment in matrix.assignments) {
        await ScoresService(repository, clock: () => now).enterOfficialScore(
          contestId,
          assignment.id,
          clientMutationId: 'entry-${mutations++}',
          baseScoreRevision: 0,
          components: {
            'time_flown': 500 + (mutations % 80),
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
      }
      await ResultsService(repository, clock: () => now).recalculate(contestId);
    }

    Future<core.PublicationIdentity> publish({
      core.Id? contest,
      core.PublicationVisibility? visibility,
    }) async {
      final id = contest ?? contestId;
      final revision = (await repository.contestRepository.findById(id))!;
      final result = await publishing.publish(
        id,
        actorId: actor,
        authority: core.Authority.director,
        clientMutationId: 'p-${mutations++}',
        sourceContestRevision: revision.revision,
      );
      if (visibility == null) return result.view.identity;
      return (await publishing.setVisibility(
        id,
        visibility,
        actorId: actor,
        authority: core.Authority.director,
      )).identity;
    }

    Future<core.PublicationIdentity> update(
      core.PublicationIdentity identity, {
      core.PublicationVisibility? visibility,
      int? hiddenThrough,
    }) => repository.publicationIdentityRepository.save(
      core.PublicationIdentity(
        id: identity.id,
        contestId: identity.contestId,
        ownerPublicProfileId: identity.ownerPublicProfileId,
        claimStatus: identity.claimStatus,
        visibility: visibility ?? identity.visibility,
        publishedAt: identity.publishedAt,
        currentProjectionId: identity.currentProjectionId,
        resultsHiddenThroughRound: hiddenThrough,
        resultsHiddenAt: hiddenThrough == null ? null : now,
        revision: identity.revision,
      ),
    );

    test('an Unlisted publication is readable by id', () async {
      await scoreEverything();
      final identity = await publish();

      final read = await reading.read(identity.id);

      expect(read.publicationId, identity.id.value);
      expect(read.visibility, 'Unlisted');
      expect(read.contest['name'], 'Spring Open');
      expect(read.disciplineType, 'F5J');
      expect(read.projectionRevision, 1);
      expect(read.participants, hasLength(4));
      expect(read.scores, hasLength(8));
      expect(read.standingRounds, hasLength(2));
      expect(read.resultsHiddenThroughRound, isNull);
    });

    test(
      'a Public publication is readable and listed; Unlisted is not',
      () async {
        final unlisted = await publish();
        final other = await drawnContest(
          repository,
          actor,
          mutationPrefix: 'other',
        );
        final public = await publish(
          contest: other,
          visibility: core.PublicationVisibility.public,
        );

        final listed = await reading.list();

        expect([for (final p in listed) p.publicationId], [public.id.value]);
        expect(listed.single.contest['name'], 'Spring Open');
        expect(listed.single.disciplineType, 'F5J');
        expect((await reading.read(public.id)).visibility, 'Public');
        expect((await reading.read(unlisted.id)).visibility, 'Unlisted');
      },
    );

    test('the listing is newest first and pages', () async {
      final ids = <core.Id>[];
      for (var i = 0; i < 3; i++) {
        now = now.add(const Duration(hours: 1));
        final contest = i == 0
            ? contestId
            : await drawnContest(repository, actor, mutationPrefix: 'extra-$i');
        ids.add(
          (await publish(
            contest: contest,
            visibility: core.PublicationVisibility.public,
          )).id,
        );
      }

      final all = await reading.list();
      final page = await reading.list(limit: 1, offset: 1);

      expect(
        [for (final p in all) p.publicationId],
        [for (final id in ids.reversed) id.value],
      );
      expect([for (final p in page) p.publicationId], [ids[1].value]);
      await expectLater(reading.list(limit: 0), throwsA(isA<ArgumentError>()));
      await expectLater(
        reading.list(offset: -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('a Delisted or unknown publication is not found', () async {
      final identity = await publish(
        visibility: core.PublicationVisibility.public,
      );
      await update(
        await repository.publicationIdentityRepository.findById(identity.id)
            as core.PublicationIdentity,
        visibility: core.PublicationVisibility.delisted,
      );

      await expectLater(
        reading.read(identity.id),
        throwsA(isA<core.EntityNotFoundError>()),
      );
      await expectLater(
        reading.read(core.Id.create()),
        throwsA(isA<core.EntityNotFoundError>()),
      );
      expect(await reading.list(), isEmpty);
    });

    test('standings beyond the hidden round never reach the reader', () async {
      await scoreEverything();
      final identity = await publish();
      await update(identity, hiddenThrough: 1);

      final read = await reading.read(identity.id);

      expect(read.resultsHiddenThroughRound, 1);
      expect(
        [
          for (final round in read.standingRounds)
            (round! as Map)['as_of_round'],
        ],
        [1],
      );
      expect(
        jsonEncode(read.toJson()['standings']),
        isNot(contains('"as_of_round":2')),
      );
      // Round scores stay public while standings are hidden.
      expect(read.scores, hasLength(8));
    });

    test(
      'display details are shown, and gone once a pilot is redacted',
      () async {
        final identity = await publish();
        final rows = await repository.publicationParticipantRepository
            .listForPublication(identity.id);
        final redacted = rows.first;
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

        final read = await reading.read(identity.id);

        final byKey = {
          for (final p in read.participants.cast<Map<String, Object?>>())
            p['pilot_key']: p,
        };
        expect(byKey[redacted.pilotKey]!['details'], isNull);
        for (final row in rows.skip(1)) {
          final details = byKey[row.pilotKey]!['details']! as Map;
          expect(details['last_name'], 'Test');
          expect(details['club'], startsWith('Club'));
        }
        expect(jsonEncode(read.toJson()), isNot(contains('example.com')));
      },
    );

    test('the public view carries no owner or private data', () async {
      await scoreEverything();
      final identity = await publish();

      final text = jsonEncode((await reading.read(identity.id)).toJson());

      for (final secret in [
        'example.com',
        'FAI-',
        'owner',
        'verification',
        'client_mutation_id',
        actor.value,
        identity.ownerPublicProfileId!.value,
      ]) {
        expect(text, isNot(contains(secret)), reason: secret);
      }
    });
  });
}
