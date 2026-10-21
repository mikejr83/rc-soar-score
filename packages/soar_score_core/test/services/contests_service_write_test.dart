import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../models/contest/fixtures.dart';
import '../support/memory_repositories.dart';

void main() {
  final now = DateTime.utc(2026, 10, 6, 12);
  final owner = id(1);
  final contestId = id(0x20);

  late MemoryContestRepository contests;
  late ContestsService service;

  MutationMetadata metadata([String key = 'm1']) => MutationMetadata(
    clientMutationId: key,
    authority: Authority.director,
    clientTime: now,
    actorId: owner,
  );

  ContestDetails details({String name = 'Spring Open', String? city}) =>
      ContestDetails(
        name: name,
        startDateTime: start,
        endDateTime: end,
        city: city,
      );

  NewContest newContest({String name = 'Spring Open'}) => NewContest(
    id: contestId,
    details: details(name: name),
    timezone: 'America/Denver',
  );

  setUp(() {
    contests = MemoryContestRepository();
    service = ContestsService(
      FakeRepository(contestRepository: contests),
      clock: () => now,
    );
  });

  group('createContest', () {
    test('stores a Created contest owned by the caller', () async {
      final created = await service.createContest(
        newContest(),
        ownerAccountId: owner,
        metadata: metadata(),
      );

      expect(created.id, contestId);
      expect(created.name, 'Spring Open');
      expect(created.lifecycleState, LifecycleState.created);
      expect(created.scoringAccess, ScoringAccess.closed);
      expect(created.adminLock, AdminLock.unlocked);
      expect(created.ownerAccountId, owner);
      expect(created.createdAt, now);
      expect(contests.metadata.single.actorId, owner);
      expect(contests.metadata.single.authority, Authority.director);
    });

    test('turns blank optional text into null', () async {
      final created = await service.createContest(
        NewContest(
          id: contestId,
          details: details(city: '   '),
          timezone: 'America/Denver',
        ),
        ownerAccountId: owner,
        metadata: metadata(),
      );
      expect(created.city, isNull);
    });

    test('repeating the same request returns the stored contest', () async {
      final first = await service.createContest(
        newContest(),
        ownerAccountId: owner,
        metadata: metadata(),
      );
      final second = await service.createContest(
        newContest(),
        ownerAccountId: owner,
        metadata: metadata('m2'),
      );

      expect(second, first);
      expect(contests.stored, hasLength(1));
      expect(contests.metadata, hasLength(1));
    });

    test('the same id with different content is a conflict', () async {
      await service.createContest(
        newContest(),
        ownerAccountId: owner,
        metadata: metadata(),
      );

      expect(
        () => service.createContest(
          newContest(name: 'Another name'),
          ownerAccountId: owner,
          metadata: metadata('m2'),
        ),
        throwsA(isA<AlreadyStoredError>()),
      );
    });

    test('invalid details are an ArgumentError', () {
      expect(
        () => service.createContest(
          newContest(name: ' '),
          ownerAccountId: owner,
          metadata: metadata(),
        ),
        throwsArgumentError,
      );
      expect(
        () => service.createContest(
          NewContest(
            id: contestId,
            details: ContestDetails(
              name: 'x',
              startDateTime: end,
              endDateTime: start,
            ),
            timezone: 'America/Denver',
          ),
          ownerAccountId: owner,
          metadata: metadata(),
        ),
        throwsArgumentError,
      );
    });
  });

  group('getContest', () {
    test('throws EntityNotFoundError for an unknown id', () {
      expect(
        () => service.getContest(contestId),
        throwsA(isA<EntityNotFoundError>()),
      );
    });
  });

  group('updateContest', () {
    setUp(() async {
      await service.createContest(
        newContest(),
        ownerAccountId: owner,
        metadata: metadata(),
      );
    });

    test(
      'replaces the details, keeps the rest and bumps the revision',
      () async {
        final updated = await service.updateContest(
          contestId,
          details(name: 'Spring Classic', city: 'Boulder'),
          baseRevision: 0,
          metadata: metadata('m2'),
        );

        expect(updated.name, 'Spring Classic');
        expect(updated.city, 'Boulder');
        expect(updated.timezone, 'America/Denver');
        expect(updated.ownerAccountId, owner);
        expect(updated.lifecycleState, LifecycleState.created);
        expect(updated.revision, 1);
      },
    );

    test('a stale base revision is refused and changes nothing', () async {
      await service.updateContest(
        contestId,
        details(name: 'First'),
        baseRevision: 0,
        metadata: metadata('m2'),
      );

      expect(
        () => service.updateContest(
          contestId,
          details(name: 'Second'),
          baseRevision: 0,
          metadata: metadata('m3'),
        ),
        throwsA(isA<StaleRevisionError>()),
      );
      expect(contests.stored[contestId]!.name, 'First');
    });

    test('an unknown contest is not found', () {
      expect(
        () => service.updateContest(
          id(0x99),
          details(),
          baseRevision: 0,
          metadata: metadata('m2'),
        ),
        throwsA(isA<EntityNotFoundError>()),
      );
    });
  });

  group('applyAction', () {
    setUp(() async {
      await service.createContest(
        newContest(),
        ownerAccountId: owner,
        metadata: metadata(),
      );
    });

    test('stores the changed contest with a new revision', () async {
      final locked = await service.applyAction(
        contestId,
        ContestAction.lock,
        baseRevision: 0,
        metadata: metadata('m2'),
      );

      expect(locked.adminLock, AdminLock.locked);
      expect(locked.revision, 1);
      expect(contests.metadata.last.clientMutationId, 'm2');
    });

    test(
      'a success leaves one StateTransition event with who and what',
      () async {
        await service.applyAction(
          contestId,
          ContestAction.lock,
          baseRevision: 0,
          metadata: metadata('m2'),
        );

        final event = contests.audits.single;
        expect(event.action, AuditAction.stateTransition);
        expect(event.entityType, 'Contest');
        expect(event.contestId, contestId);
        expect(event.actorId, owner);
        expect(event.authority, Authority.director);
        expect(event.serverTimestamp, now);
        expect(event.baseRevision, 0);
        expect(event.resultingRevision, 1);
        expect(event.reason, 'lock: AdminLock Unlocked → Locked');
        expect(ContestTransitionAudit.actionOf(event), ContestAction.lock);
      },
    );

    test('completing records every field it changes', () async {
      final running = Contest.fromJson({
        ...contests.stored[contestId]!.toJson(),
        'lifecycle_state': 'Running',
        'scoring_access': 'Open',
      });
      contests.stored[contestId] = running;

      await service.applyAction(
        contestId,
        ContestAction.complete,
        baseRevision: 0,
        metadata: metadata('m2'),
      );

      expect(
        contests.audits.single.reason,
        'complete: LifecycleState Running → Completed; '
        'ScoringAccess Open → Closed',
      );
    });

    test('a stale base revision is reported before the state rules', () async {
      expect(
        () => service.applyAction(
          contestId,
          ContestAction.complete,
          baseRevision: 5,
          metadata: metadata('m2'),
        ),
        throwsA(isA<StaleRevisionError>()),
      );
    });

    test('a refused action changes nothing', () async {
      expect(
        () => service.applyAction(
          contestId,
          ContestAction.complete,
          baseRevision: 0,
          metadata: metadata('m2'),
        ),
        throwsA(isA<ContestStateError>()),
      );
      expect(contests.stored[contestId]!.revision, 0);
      expect(contests.audits, isEmpty);
    });

    test('an unknown contest is not found', () {
      expect(
        () => service.applyAction(
          id(0x99),
          ContestAction.lock,
          baseRevision: 0,
          metadata: metadata('m2'),
        ),
        throwsA(isA<EntityNotFoundError>()),
      );
    });
  });
}
