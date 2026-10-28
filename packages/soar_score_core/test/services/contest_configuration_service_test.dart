import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../models/contest/fixtures.dart';
import '../support/memory_repositories.dart';

void main() {
  final now = DateTime.utc(2026, 10, 6, 12);
  final owner = id(1);
  final contestId = id(0x20);
  final f5jId = SystemDisciplineProfiles.f5jId;

  late MemoryContestRepository contests;
  late MemoryConfigurationRevisionRepository revisions;
  late ContestConfigurationService service;
  var nextId = 0x1000;

  MutationMetadata metadata([String key = 'm1']) => MutationMetadata(
    clientMutationId: key,
    authority: Authority.director,
    clientTime: now,
    actorId: owner,
  );

  ConfigurationInput input({
    int base = 0,
    Id? profileId,
    Map<String, Object?> core = const {},
    Map<String, Object?> discipline = const {'working_time': 600},
    Id? landingTableId,
    String? notes,
  }) => ConfigurationInput(
    baseRevisionNumber: base,
    disciplineProfileId: profileId ?? f5jId,
    config: ContestConfig(core: core, discipline: discipline),
    landingTableId: landingTableId,
    notes: notes,
  );

  Future<SavedConfiguration> save(
    ConfigurationInput i, {
    Id? forContest,
    String key = 'm1',
  }) => service.save(
    forContest ?? contestId,
    i,
    createdBy: owner,
    metadata: metadata(key),
  );

  Future<void> seedContest({
    LifecycleState state = LifecycleState.created,
    AdminLock lock = AdminLock.unlocked,
    Id? ownerId,
  }) async {
    contests.stored[contestId] = Contest(
      id: contestId,
      name: 'Spring Open',
      startDateTime: start,
      endDateTime: end,
      timezone: 'America/Denver',
      ownerAccountId: ownerId ?? owner,
      lifecycleState: state,
      adminLock: lock,
      createdAt: DateTime.utc(2026, 9),
      updatedAt: DateTime.utc(2026, 9),
    );
  }

  setUp(() async {
    contests = MemoryContestRepository();
    revisions = MemoryConfigurationRevisionRepository(contests);
    service = ContestConfigurationService(
      FakeRepository(
        contestRepository: contests,
        configurationRepository: revisions,
        profileRepository: MemoryDisciplineProfileRepository(
          SystemDisciplineProfiles.all,
        ),
        landingTableRepository: MemoryLandingTableRepository(
          SystemLandingTables.all,
        ),
      ),
      clock: () => now,
      newId: () => id(nextId++),
    );
    await seedContest();
  });

  group('save', () {
    test('stores revision 1 and moves the contest to Configuring', () async {
      final saved = await save(input(notes: '  first draft  '));

      expect(saved.revision.revisionNumber, 1);
      expect(saved.revision.contestId, contestId);
      expect(saved.revision.disciplineProfileId, f5jId);
      expect(saved.revision.createdBy, owner);
      expect(saved.revision.createdAt, now);
      expect(saved.revision.notes, 'first draft');
      expect(saved.revision.config.discipline, {'working_time': 600});
      expect(saved.contest.lifecycleState, LifecycleState.configuring);
      expect(saved.contest.revision, 1);
      expect(revisions.stored, hasLength(1));
    });

    test('the F5J default landing table is used when none is given', () async {
      final saved = await save(input());
      expect(saved.revision.landingTableId, SystemLandingTables.f5jStandardId);
    });

    test('a system landing table can be chosen', () async {
      final saved = await save(
        input(landingTableId: SystemLandingTables.f5jDistanceId),
      );
      expect(saved.revision.landingTableId, SystemLandingTables.f5jDistanceId);
    });

    test('the next revision adds one and keeps the history', () async {
      final first = await save(input());

      final second = await save(
        input(base: 1, discipline: {'working_time': 480}),
        key: 'm2',
      );

      expect(second.revision.revisionNumber, 2);
      expect(second.contest.revision, first.contest.revision + 1);
      expect(
        (await revisions.listForContest(contestId))
            .map((r) => r.revisionNumber),
        [1, 2],
      );
      expect((await revisions.latestForContest(contestId))!.config.discipline, {
        'working_time': 480,
      });
    });

    test(
      'a stale base revision number is refused and stores nothing',
      () async {
        await save(input());

        await expectLater(
          save(input(base: 0), key: 'm2'),
          throwsA(isA<StaleRevisionError>()),
        );
        expect(revisions.stored, hasLength(1));
      },
    );

    test('a contest changed meanwhile is refused and stores nothing', () async {
      final saved = await save(input());
      // Someone else saved the contest after this request read it.
      contests.stored[contestId] = Contest.fromJson({
        ...saved.contest.toJson(),
        'revision': saved.contest.revision + 1,
      });
      final stale = ContestConfigurationService(
        _RacingRepository(contests, revisions, saved.contest),
        clock: () => now,
        newId: () => id(nextId++),
      );

      await expectLater(
        stale.save(
          contestId,
          input(base: 1, discipline: {'working_time': 480}),
          createdBy: owner,
          metadata: metadata('m2'),
        ),
        throwsA(isA<StaleRevisionError>()),
      );
      expect(revisions.stored, hasLength(1));
    });

    test('an unknown contest is not found', () {
      expect(
        () => save(input(), forContest: id(0x99)),
        throwsA(isA<EntityNotFoundError>()),
      );
    });

    test('rejects an unknown discipline profile', () {
      expect(() => save(input(profileId: id(0x77))), throwsArgumentError);
    });

    test('rejects a different discipline after the first revision', () async {
      await save(input());

      await expectLater(
        save(
          input(base: 1, profileId: SystemDisciplineProfiles.f3jId),
          key: 'm2',
        ),
        throwsA(
          isA<ContestStateError>().having(
            (e) => e.code,
            'code',
            'discipline_fixed',
          ),
        ),
      );
    });

    test('rejects invalid core options and unknown core keys', () async {
      await expectLater(
        save(input(core: {'decimal_places': 9})),
        throwsArgumentError,
      );
      await expectLater(
        save(input(core: {'teams_enabled': true})),
        throwsArgumentError,
      );
      await expectLater(
        save(input(core: {'decimal_place': 1})),
        throwsArgumentError,
      );
      expect(revisions.stored, isEmpty);
    });

    test(
      'rejects invalid discipline settings, all reported together',
      () async {
        await expectLater(
          save(input(discipline: {'working_time': 0, 'nope': 1})),
          throwsA(
            isA<ScoringValidationError>().having(
              (e) => e.issues.length,
              'issues',
              2,
            ),
          ),
        );
        expect(revisions.stored, isEmpty);
      },
    );

    test(
      'rejects a landing table that does not exist or is not usable',
      () async {
        await expectLater(
          save(input(landingTableId: id(0x88))),
          throwsArgumentError,
        );
      },
    );

    test('rejects a landing table for a discipline without one', () async {
      final noLanding = ContestConfigurationService(
        FakeRepository(
          contestRepository: contests,
          configurationRepository: revisions,
          profileRepository: MemoryDisciplineProfileRepository([
            DisciplineProfileWithRules(
              profile: SystemDisciplineProfiles.f5j.profile,
              configFields: const [],
              scoreFields: const [],
              validations: const [],
              formulas: const [],
              rules: const [],
            ),
          ]),
          landingTableRepository: MemoryLandingTableRepository(const []),
        ),
        clock: () => now,
      );

      await expectLater(
        noLanding.save(
          contestId,
          input(
            discipline: const {},
            landingTableId: SystemLandingTables.f5jStandardId,
          ),
          createdBy: owner,
          metadata: metadata(),
        ),
        throwsArgumentError,
      );
    });

    test('a locked contest takes no configuration', () async {
      await seedContest(lock: AdminLock.locked);

      await expectLater(save(input()), throwsA(isA<ContestStateError>()));
      expect(revisions.stored, isEmpty);
      expect(contests.audits, isEmpty);
    });

    test('each save leaves one ConfigurationSaved event', () async {
      final first = await save(input());
      final second = await save(
        input(base: 1, discipline: {'working_time': 480}),
        key: 'm2',
      );

      expect(contests.audits, hasLength(2));
      final event = contests.audits.last;
      expect(event.action, AuditAction.configurationSaved);
      expect(event.entityType, 'ContestConfigurationRevision');
      expect(event.entityId, second.revision.id);
      expect(event.contestId, contestId);
      expect(event.actorId, owner);
      expect(event.authority, Authority.director);
      expect(event.baseRevision, 1);
      expect(event.resultingRevision, 2);
      expect(event.serverTimestamp, now);
      expect(event.outcome, AuditOutcome.success);
      expect(contests.audits.first.entityId, first.revision.id);
      expect(contests.audits.first.baseRevision, isNull);
      expect(contests.audits.first.resultingRevision, 1);
    });

    test('a refused save leaves no event', () async {
      await save(input());
      await expectLater(
        save(input(base: 0), key: 'm2'),
        throwsA(isA<StaleRevisionError>()),
      );
      expect(contests.audits, hasLength(1));
    });
  });

  group('reads', () {
    test('latest and revisions need a stored configuration', () async {
      await expectLater(
        service.latest(contestId),
        throwsA(isA<EntityNotFoundError>()),
      );
      expect(await service.revisions(contestId), isEmpty);

      await save(input());
      await save(input(base: 1, discipline: {'working_time': 480}), key: 'm2');

      expect((await service.latest(contestId)).revisionNumber, 2);
      expect((await service.revisions(contestId)).length, 2);
    });

    test('an unknown contest is not found', () {
      expect(
        () => service.latest(id(0x99)),
        throwsA(isA<EntityNotFoundError>()),
      );
      expect(
        () => service.revisions(id(0x99)),
        throwsA(isA<EntityNotFoundError>()),
      );
    });
  });
}

/// Serves the contest as it was before a concurrent save, so the service
/// works from an out-of-date copy.
class _RacingRepository extends FakeRepository {
  _RacingRepository(
    MemoryContestRepository contests,
    MemoryConfigurationRevisionRepository revisions,
    Contest outdated,
  ) : super(
        contestRepository: _OutdatedContests(contests, outdated),
        configurationRepository: revisions,
        profileRepository: MemoryDisciplineProfileRepository(
          SystemDisciplineProfiles.all,
        ),
        landingTableRepository: MemoryLandingTableRepository(
          SystemLandingTables.all,
        ),
      );
}

class _OutdatedContests extends MemoryContestRepository {
  _OutdatedContests(this._real, this._outdated);

  final MemoryContestRepository _real;
  final Contest _outdated;

  @override
  Future<Contest?> findById(Id id) async => _outdated;

  @override
  Future<Contest> save(
    Contest contest, {
    required MutationMetadata metadata,
    AuditEvent? audit,
  }) => _real.save(contest, metadata: metadata, audit: audit);
}
