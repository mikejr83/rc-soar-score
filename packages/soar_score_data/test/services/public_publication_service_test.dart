import 'dart:convert';

import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/drawn_contest.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

/// Counts the reads that give a listing its live status, to show they do not
/// grow with the page.
class _Counts {
  int contestById = 0;
  int contestsByIds = 0;
  int scoreTimes = 0;
  int invitationTimes = 0;
  int invitationLists = 0;
}

class _CountingContests implements core.ContestRepository {
  _CountingContests(this.inner, this.counts);
  final core.ContestRepository inner;
  final _Counts counts;

  @override
  Future<core.Contest?> findById(core.Id id) {
    counts.contestById++;
    return inner.findById(id);
  }

  @override
  Future<Map<core.Id, core.Contest>> findByIds(Iterable<core.Id> ids) {
    counts.contestsByIds++;
    return inner.findByIds(ids);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _CountingScores implements core.OfficialScoreRepository {
  _CountingScores(this.inner, this.counts);
  final core.OfficialScoreRepository inner;
  final _Counts counts;

  @override
  Future<Map<core.Id, DateTime>> latestSetAtForContests(Iterable<core.Id> ids) {
    counts.scoreTimes++;
    return inner.latestSetAtForContests(ids);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _CountingInvitations implements core.InvitationRepository {
  _CountingInvitations(this.inner, this.counts);
  final core.InvitationRepository inner;
  final _Counts counts;

  @override
  Future<Map<core.Id, DateTime>> latestIssuedAtForContests(
    Iterable<core.Id> ids,
  ) {
    counts.invitationTimes++;
    return inner.latestIssuedAtForContests(ids);
  }

  @override
  Future<List<core.Invitation>> listForContest(core.Id contestId) {
    counts.invitationLists++;
    return inner.listForContest(contestId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// The repositories the public service reads, three of them counted.
class _CountingRepository implements core.Repository {
  _CountingRepository(this.inner, this.counts);
  final Repository inner;
  final _Counts counts;

  @override
  late final contestRepository = _CountingContests(
    inner.contestRepository,
    counts,
  );
  @override
  late final officialScoreRepository = _CountingScores(
    inner.officialScoreRepository,
    counts,
  );
  @override
  late final invitationRepository = _CountingInvitations(
    inner.invitationRepository,
    counts,
  );
  @override
  core.PublicationIdentityRepository get publicationIdentityRepository =>
      inner.publicationIdentityRepository;
  @override
  core.PublicationProjectionRepository get publicationProjectionRepository =>
      inner.publicationProjectionRepository;
  @override
  core.PublicationParticipantRepository get publicationParticipantRepository =>
      inner.publicationParticipantRepository;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

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
    var readNow = DateTime.utc(2026, 10, 17, 22);

    setUp(() async {
      inst = await Installation.open(backend, profile: DatabaseProfile.server);
      await SystemDataSeeder(inst.db).seed();
      repository = Repository(inst.db);
      now = DateTime.utc(2026, 10, 17, 15);
      readNow = DateTime.utc(2026, 10, 17, 22);
      publishing = PublicationService(repository, clock: () => now);
      reading = PublicPublicationService(repository, clock: () => readNow);
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

    group('contest status (#454)', () {
      Future<String> statusOf(core.Id id) async =>
          (await reading.read(id)).contest['status']! as String;

      test('a running contest scored within 48 hours is in progress', () async {
        await scoreEverything();
        final identity = await publish();

        readNow = now.add(const Duration(hours: 47));

        expect(await statusOf(identity.id), 'in_progress');
      });

      test('a running contest idle for more than 48 hours is completed, '
          'in the list too', () async {
        await scoreEverything();
        final identity = await publish(
          visibility: core.PublicationVisibility.public,
        );

        readNow = now.add(const Duration(hours: 49));

        expect(await statusOf(identity.id), 'completed');
        final listed = (await reading.list(
          from: DateTime.utc(2026, 1),
          to: DateTime.utc(2026, 12),
          today: readNow,
        )).publications;
        expect(listed.single.contest['status'], 'completed');
        // The lifecycle state is untouched: nothing was written back.
        final contest = (await repository.contestRepository.findById(
          contestId,
        ))!;
        expect(contest.lifecycleState, isNot(core.LifecycleState.completed));
      });

      test('a contest published before its start is upcoming', () async {
        await scoreEverything();
        final identity = await publish(
          visibility: core.PublicationVisibility.public,
        );

        // The contest starts 2026-10-17 14:00 UTC.
        readNow = DateTime.utc(2026, 10, 10);
        expect(await statusOf(identity.id), 'upcoming');
        final listed = (await reading.list(
          from: DateTime.utc(2026, 1),
          to: DateTime.utc(2026, 12),
          today: readNow,
        )).publications;
        expect(listed.single.contest['status'], 'upcoming');
      });

      test('a completed contest is completed at once', () async {
        await scoreEverything();
        final identity = await publish();
        final contest = (await repository.contestRepository.findById(
          contestId,
        ))!;
        await repository.contestRepository.save(
          contest.copyWithState(
            lifecycleState: core.LifecycleState.completed,
            updatedAt: now,
          ),
          metadata: core.MutationMetadata(
            clientMutationId: 'complete-${mutations++}',
            authority: core.Authority.director,
            clientTime: now,
            actorId: actor,
          ),
        );

        expect(await statusOf(identity.id), 'completed');
      });

      test('scoring again after it read as completed makes it in progress, '
          'even though the projection is older', () async {
        await scoreEverything();
        final identity = await publish();
        readNow = now.add(const Duration(hours: 60));
        expect(await statusOf(identity.id), 'completed');

        final matrix = await MatrixService(repository).current(contestId);
        final assignment = matrix.assignments.first;
        final later = readNow.subtract(const Duration(hours: 1));
        await ScoresService(repository, clock: () => later).enterOfficialScore(
          contestId,
          assignment.id,
          clientMutationId: 'entry-${mutations++}',
          baseScoreRevision: 1,
          components: {
            'time_flown': 400,
            'launch_height': 200,
            'landing': 'points_50',
          },
          actorId: actor,
          metadata: core.MutationMetadata(
            clientMutationId: 'meta-${mutations++}',
            authority: core.Authority.director,
            clientTime: later,
            actorId: actor,
          ),
          reason: 'late correction',
        );

        // Not republished: the live contest answers, not the projection.
        expect(await statusOf(identity.id), 'in_progress');
      });

      test('a live contest with no activity ignores an older captured one, '
          'and the clock runs from its start', () async {
        // Nothing scored: the live contest has no activity.
        final identity = await publish();
        final current = (await repository.publicationProjectionRepository
            .findById(identity.currentProjectionId!))!;
        final json = current.toJson();
        // A second projection that captured activity after the start (the
        // contest starts 2026-10-17 14:00 UTC).
        final captured = core.PublicationProjection.fromJson({
          ...json,
          'id': core.Id.create().value,
          'projection_revision': 2,
          'client_mutation_id': 'captured-activity',
          'contest_identity': {
            ...(json['contest_identity']! as Map<String, Object?>),
            'last_activity_at': '2026-10-19T10:00:00.000Z',
          },
        });
        await repository.publicationProjectionRepository.append(captured);
        await repository.publicationIdentityRepository.save(
          core.PublicationIdentity(
            id: identity.id,
            contestId: identity.contestId,
            ownerPublicProfileId: identity.ownerPublicProfileId,
            claimStatus: identity.claimStatus,
            visibility: identity.visibility,
            publishedAt: identity.publishedAt,
            currentProjectionId: captured.id,
            contestName: identity.contestName,
            contestStartsAt: identity.contestStartsAt,
            contestEndsAt: identity.contestEndsAt,
            venue: identity.venue,
            revision: identity.revision,
          ),
        );

        // 58 hours after the start, 14 after the captured activity.
        readNow = DateTime.utc(2026, 10, 20);
        expect(await statusOf(identity.id), 'completed');
      });

      test('the projection stands in when the server has no contest', () async {
        await scoreEverything();
        final identity = await publish();
        await repository.publicationIdentityRepository.save(
          core.PublicationIdentity(
            id: identity.id,
            contestId: null,
            ownerPublicProfileId: identity.ownerPublicProfileId,
            claimStatus: identity.claimStatus,
            visibility: identity.visibility,
            publishedAt: identity.publishedAt,
            currentProjectionId: identity.currentProjectionId,
            contestName: identity.contestName,
            contestStartsAt: identity.contestStartsAt,
            contestEndsAt: identity.contestEndsAt,
            venue: identity.venue,
            revision: identity.revision,
          ),
        );

        readNow = now.add(const Duration(hours: 47));
        expect(await statusOf(identity.id), 'in_progress');
        readNow = now.add(const Duration(hours: 49));
        expect(await statusOf(identity.id), 'completed');
      });
    });

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

    test('a listing reads its live status inputs in a fixed number of '
        'queries', () async {
      for (var i = 0; i < 3; i++) {
        await publishPublic('Contest $i', DateTime.utc(2026, 10, 17, 14));
      }
      final counts = _Counts();
      final counted = PublicPublicationService(
        _CountingRepository(repository, counts),
        clock: () => readNow,
      );

      final listed = (await counted.list()).publications;

      expect(listed, hasLength(3));
      expect(counts.contestById, 0);
      expect(counts.contestsByIds, 1);
      expect(counts.scoreTimes, 1);
      expect(counts.invitationTimes, 1);
      expect(counts.invitationLists, 0);
    });

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

      // Sunday 2026-11-01 evening, then Monday: the cutoff is Nov 8 both days.
      for (final day in [
        DateTime.utc(2026, 11, 1, 21),
        DateTime.utc(2026, 11, 2),
      ]) {
        final onDay = PublicPublicationService(repository, clock: () => day);
        expect(await names(await onDay.list()), ['Next week']);
      }
      // A caller a day off the server's still gets its own day's cutoff.
      expect(
        await names(await reading.list(today: DateTime.utc(2026, 10, 18))),
        isEmpty,
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

    test('a venue search matches its parts in any order', () async {
      await publishPublic(
        'Gator Classic',
        DateTime.utc(2026, 10, 17, 14),
        host: 'Flying Gators RC Club',
        city: 'Gainesville',
      );

      expect(await names(await reading.list(venue: 'Gainesville, Gators')), [
        'Gator Classic',
      ]);
      expect(
        await names(await reading.list(venue: 'Gainesville, Seattle')),
        isEmpty,
      );
    });

    test('a Public record without a current projection is not listed and '
        'does not shorten the page', () async {
      final kept = await publishPublic('Kept', DateTime.utc(2026, 10, 17, 14));
      await repository.publicationIdentityRepository.save(
        core.PublicationIdentity(
          id: core.Id.create(),
          verificationEmail: 'x@example.com',
          visibility: core.PublicationVisibility.public,
          publishedAt: now,
          contestName: 'Orphan',
          contestStartsAt: DateTime.utc(2026, 10, 18, 9),
        ),
      );

      final page = await reading.list(limit: 1);

      expect(
        [for (final p in page.publications) p.publicationId],
        [kept.value],
      );
    });

    test(
      'a publication with no projection yet is pending, not visible',
      () async {
        final pending = core.Id.create();
        await repository.publicationIdentityRepository.save(
          core.PublicationIdentity(
            id: pending,
            verificationEmail: 'x@example.com',
          ),
        );

        await expectLater(
          reading.read(pending),
          throwsA(
            isA<core.ForbiddenError>().having(
              (e) => e.code,
              'code',
              'contest_not_visible',
            ),
          ),
        );
      },
    );

    test('a caller far from the server day cannot lift the cap', () async {
      await publishPublic('Far', DateTime.utc(2026, 11, 7, 12));

      // The service clock is 2026-10-17; a year ahead is clamped to Oct 18.
      expect(
        await names(await reading.list(today: DateTime.utc(2027, 10, 17))),
        isEmpty,
      );
      expect(await names(await reading.list(limit: 1000)), isEmpty);
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

    test('the summary follows the date filters, not the name', () async {
      await publishPublic('Flown', DateTime.utc(2026, 10, 10, 14));
      await publishPublic('Running', DateTime.utc(2026, 10, 17, 14));
      await publishPublic('Old', DateTime.utc(2026, 8, 1, 14));

      final old = await reading.list(
        from: DateTime.utc(2026, 7, 1),
        to: DateTime.utc(2026, 8, 31),
      );
      final named = await reading.list(name: 'Old');
      final all = await reading.list(from: DateTime.utc(2026, 1, 1));

      expect(old.recentCount, 1);
      expect(await names(old), ['Old']);
      expect(named.recentCount, 2, reason: 'a name filter keeps the window');
      expect(all.recentCount, 3);
    });

    test('a from filter does not count a contest that started before it, and '
        'a to filter is not limited to 30 days', () async {
      // Starts 2026-10-10, ends the 12th; the clock is 2026-10-17.
      await publishPublic(
        'Spans',
        DateTime.utc(2026, 10, 10, 14),
        end: DateTime.utc(2026, 10, 12, 14),
      );
      await publishPublic('Old', DateTime.utc(2026, 8, 1, 14));

      final fromAfterStart = await reading.list(
        from: DateTime.utc(2026, 10, 11),
      );
      final toOnly = await reading.list(to: DateTime.utc(2026, 10, 17));

      expect(await names(fromAfterStart), isEmpty);
      expect(fromAfterStart.recentCount, 0);
      expect(await names(toOnly), ['Spans', 'Old']);
      expect(toOnly.recentCount, 2);
    });

    test('a contest starting later this week is in the summary', () async {
      // The clock is Saturday 2026-10-17; the list runs through Sunday.
      await publishPublic('Tomorrow', DateTime.utc(2026, 10, 18, 9));

      final list = await reading.list();

      expect(await names(list), ['Tomorrow']);
      expect(list.recentCount, 1);
    });

    test(
      'a Delisted publication is not visible and an unknown one not found',
      () async {
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
          throwsA(
            isA<core.ForbiddenError>().having(
              (e) => e.code,
              'code',
              'contest_not_visible',
            ),
          ),
        );
        await expectLater(
          reading.read(core.Id.create()),
          throwsA(isA<core.EntityNotFoundError>()),
        );
        expect((await reading.list()).publications, isEmpty);
      },
    );

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
