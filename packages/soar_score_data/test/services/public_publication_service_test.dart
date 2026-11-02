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
      reading = PublicPublicationService(
        repository,
        clock: () => DateTime.utc(2026, 10, 17, 22),
      );
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
        contestName: identity.contestName,
        contestStartsAt: identity.contestStartsAt,
        contestEndsAt: identity.contestEndsAt,
        venue: identity.venue,
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

        final listed = (await reading.list()).publications;

        expect([for (final p in listed) p.publicationId], [public.id.value]);
        expect(listed.single.contest['name'], 'Spring Open');
        expect(listed.single.disciplineType, 'F5J');
        expect((await reading.read(public.id)).visibility, 'Public');
        expect((await reading.read(unlisted.id)).visibility, 'Unlisted');
      },
    );

    /// Publishes a Public contest with the given details.
    Future<core.Id> publishPublic(
      String name,
      DateTime start, {
      DateTime? end,
      String? host,
      String? city,
    }) async {
      final contest = await drawnContest(
        repository,
        actor,
        mutationPrefix: 'c-${mutations++}',
        name: name,
        start: start,
        end: end ?? start.add(const Duration(days: 1)),
        host: host,
        city: city,
      );
      return (await publish(
        contest: contest,
        visibility: core.PublicationVisibility.public,
      )).id;
    }

    Future<List<String>> names(PublicPublicationList list) async => [
      for (final p in list.publications) p.contest['name']! as String,
    ];

    // The service's clock is Saturday 2026-10-17; the coming Sunday is Oct 18.
    test('the listing is by contest start, newest first, and pages', () async {
      final older = await publishPublic('Older', DateTime.utc(2026, 10, 3, 14));
      final newest = await publishPublic(
        'Newest',
        DateTime.utc(2026, 10, 18, 9),
      );
      final middle = await publishPublic(
        'Middle',
        DateTime.utc(2026, 10, 10, 14),
      );

      final all = await reading.list();
      final page = await reading.list(limit: 1, offset: 1);

      expect(
        [for (final p in all.publications) p.publicationId],
        [newest.value, middle.value, older.value],
      );
      expect(
        [for (final p in page.publications) p.publicationId],
        [middle.value],
      );
      await expectLater(reading.list(limit: 0), throwsA(isA<ArgumentError>()));
      await expectLater(
        reading.list(offset: -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('without an end date only contests through the coming Sunday are '
        'listed', () async {
      await publishPublic('Sunday', DateTime.utc(2026, 10, 18, 20));
      await publishPublic('Monday', DateTime.utc(2026, 10, 19, 0));
      await publishPublic('Later', DateTime.utc(2026, 11, 7, 12));

      expect(await names(await reading.list()), ['Sunday']);
      expect(
        await names(await reading.list(from: DateTime.utc(2026, 10, 19))),
        isEmpty,
      );
      expect(
        await names(await reading.list(name: 'later', venue: '')),
        isEmpty,
      );
    });

    test('on a Sunday the coming Sunday is the following one', () async {
      await publishPublic('Next week', DateTime.utc(2026, 11, 7, 12));
      await publishPublic('Too far', DateTime.utc(2026, 11, 9, 12));

      // Sunday 2026-11-01 evening.
      final sunday = DateTime.utc(2026, 11, 1, 21);
      expect(await names(await reading.list(today: sunday)), ['Next week']);
      // The next day the cutoff is Nov 8: same answer.
      expect(
        await names(await reading.list(today: DateTime.utc(2026, 11, 2))),
        ['Next week'],
      );
    });

    test('an end date lifts the cap and bounds the start day', () async {
      await publishPublic('Near', DateTime.utc(2026, 10, 17, 14));
      await publishPublic('Far', DateTime.utc(2026, 11, 7, 12));
      await publishPublic('Farther', DateTime.utc(2026, 12, 5, 12));

      expect(await names(await reading.list(to: DateTime.utc(2026, 11, 7))), [
        'Far',
        'Near',
      ]);
      expect(
        await names(
          await reading.list(
            from: DateTime.utc(2026, 11, 6),
            to: DateTime.utc(2026, 11, 9),
          ),
        ),
        ['Far'],
      );
      await expectLater(
        reading.list(
          from: DateTime.utc(2026, 11, 9),
          to: DateTime.utc(2026, 11, 6),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('name and venue match case-insensitively as substrings', () async {
      await publishPublic(
        'Gator Classic',
        DateTime.utc(2026, 10, 17, 14),
        host: 'Flying Gators RC Club',
        city: 'Gainesville',
      );
      await publishPublic('100% Sure_Thing', DateTime.utc(2026, 10, 16, 14));

      expect(await names(await reading.list(name: 'GATOR')), ['Gator Classic']);
      expect(await names(await reading.list(venue: 'gainesVILLE')), [
        'Gator Classic',
      ]);
      expect(await names(await reading.list(name: '100%')), [
        '100% Sure_Thing',
      ]);
      // `%` and `_` are literal, not wildcards.
      expect(await names(await reading.list(name: '%')), ['100% Sure_Thing']);
      expect(await names(await reading.list(name: 'S_re')), isEmpty);
      expect(await names(await reading.list(name: 'nothing')), isEmpty);
    });

    test('the summary counts contests flown in the last 30 days', () async {
      await publishPublic('Flown', DateTime.utc(2026, 10, 10, 14));
      await publishPublic('Running', DateTime.utc(2026, 10, 17, 14));
      await publishPublic('Old', DateTime.utc(2026, 8, 1, 14));
      await publishPublic('Upcoming', DateTime.utc(2026, 10, 25, 14));

      final list = await reading.list(name: 'Flown');

      expect(list.recentCount, 2);
      expect(list.toJson()['summary'], {'recent_count': 2});
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
      expect((await reading.list()).publications, isEmpty);
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
