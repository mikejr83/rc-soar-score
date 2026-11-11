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
  late Repository repository;

  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    await loadExamples(inst);
    repository = Repository(inst.db);
  });
  tearDown(() => inst.close());

  Future<int> tombstones() => inst.count('tombstones');

  group('ParticipantProfileRepository', () {
    late core.ParticipantProfileRepository repo;
    setUp(() => repo = repository.participantProfileRepository);

    final examples = [
      for (final row in exampleRows('participant_profile'))
        core.ParticipantProfile.fromJson(row),
    ];

    test('reads back the example profiles unchanged', () async {
      for (final profile in examples) {
        expect(await repo.findById(profile.id), profile);
      }
    });

    test('findById returns null for an unknown id', () async {
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test(
      'findByIds reads many profiles at once, leaving out unknown ids',
      () async {
        final unknown = core.Id.create();
        final found = await repo.findByIds([
          for (final profile in examples) profile.id,
          unknown,
          examples.first.id,
        ]);

        expect(found.keys, unorderedEquals([for (final p in examples) p.id]));
        for (final profile in examples) {
          expect(found[profile.id], profile);
        }
        expect(await repo.findByIds(const []), isEmpty);
      },
    );

    test('listForOwner returns the profiles of that account', () async {
      final owner = examples.first.ownerAccountId;
      final owned = examples.where((p) => p.ownerAccountId == owner);

      expect(await repo.listForOwner(owner), unorderedEquals(owned));
      expect(await repo.listForOwner(core.Id.create()), isEmpty);
    });

    test('save inserts a profile and bumps the revision on update', () async {
      final fresh = core.ParticipantProfile.fromJson({
        ...exampleRows('participant_profile').first,
        'id': core.Id.create().value,
        'revision': 0,
      });

      final inserted = await repo.save(fresh, metadata: metadata());
      expect(inserted.revision, 0);

      final renamed = core.ParticipantProfile.fromJson({
        ...inserted.toJson(),
        'first_name': 'Renamed',
      });
      final updated = await repo.save(renamed, metadata: metadata());
      expect(updated.revision, 1);
      expect((await repo.findById(fresh.id))?.firstName, 'Renamed');
    });

    test('save refuses a profile read at an older revision', () async {
      final stale = core.ParticipantProfile.fromJson({
        ...examples.first.toJson(),
        'revision': 0,
      });

      expect(
        repo.save(stale, metadata: metadata()),
        throwsA(isA<core.StaleRevisionError>()),
      );
    });

    core.ParticipantProfile freshProfile(String name) =>
        core.ParticipantProfile.fromJson({
          ...exampleRows('participant_profile').first,
          'id': core.Id.create().value,
          'first_name': name,
          'revision': 0,
        });

    test('saveAll stores every profile in one transaction', () async {
      final a = freshProfile('SaveAllA');
      final b = freshProfile('SaveAllB');

      final saved = await repo.saveAll([a, b], metadata: metadata());

      expect(saved.map((p) => p.id), [a.id, b.id]);
      expect(await repo.findById(a.id), isNotNull);
      expect(await repo.findById(b.id), isNotNull);
    });

    test('saveAll stores nothing when one profile is stale', () async {
      final fresh = freshProfile('SaveAllFresh');
      final stale = core.ParticipantProfile.fromJson({
        ...examples.first.toJson(),
        'revision': 0,
      });

      await expectLater(
        repo.saveAll([fresh, stale], metadata: metadata()),
        throwsA(isA<core.StaleRevisionError>()),
      );
      expect(await repo.findById(fresh.id), isNull);
    });

    test(
      'a GliderScore pilot import adds, updates and re-imports cleanly',
      () async {
        final owner = examples.first.ownerAccountId;
        final service = core.PilotImportService(repo);
        const matcher = core.PilotImportMatcher();
        final existing = core.ParticipantProfile.fromJson({
          ...freshProfile('ImportExisting').toJson(),
          'email': 'import-existing@example.test',
        });
        await repo.save(existing, metadata: metadata());

        final drafts = [
          core.PilotDraft(
            sourcePilotNo: 1,
            firstName: 'Imported',
            lastName: 'Newcomer',
            email: 'Newcomer@Example.test',
            club: 'Import Club',
          ),
          core.PilotDraft(
            sourcePilotNo: 2,
            firstName: 'Other',
            lastName: 'Name',
            email: existing.email,
            state: 'ZZ-State',
          ),
        ];

        Future<core.PilotImportOutcome> run() async {
          final matches = matcher.match(drafts, await repo.listForOwner(owner));
          return service.apply(owner, [
            for (final m in matches) core.PilotImportSelection.defaultFor(m),
          ], metadata: metadata());
        }

        final first = await run();
        expect(first.added.single.email, 'newcomer@example.test');
        expect(first.updated.single.id, existing.id);
        expect(first.updated.single.state, 'ZZ-State');
        expect(first.updated.single.firstName, existing.firstName);

        final again = await run();
        expect(again.added, isEmpty);
        expect(again.updated, isEmpty);
        expect(again.unchanged, 2);
      },
    );

    test('delete removes an unused profile and records a tombstone', () async {
      final fresh = core.ParticipantProfile.fromJson({
        ...exampleRows('participant_profile').first,
        'id': core.Id.create().value,
        'revision': 0,
      });
      await repo.save(fresh, metadata: metadata());
      final before = await tombstones();

      expect(await repo.delete(fresh.id, metadata: metadata()), isTrue);

      expect(await repo.findById(fresh.id), isNull);
      expect(await tombstones(), before + 1);
      expect(await repo.delete(fresh.id, metadata: metadata()), isFalse);
    });

    test('delete refuses a profile that has participations', () async {
      final used = examples.first.id;

      await expectLater(
        repo.delete(used, metadata: metadata()),
        throwsA(anything),
      );
      expect(await repo.findById(used), isNotNull);
    });
  });

  group('ContestParticipationRepository', () {
    late core.ContestParticipationRepository repo;
    setUp(() => repo = repository.contestParticipationRepository);

    final examples = [
      for (final row in exampleRows('contest_participation'))
        core.ContestParticipation.fromJson(row),
    ];

    test('reads back the example participations unchanged', () async {
      for (final participation in examples) {
        expect(await repo.findById(participation.id), participation);
      }
    });

    test('listForContest returns the contest participations', () async {
      final contestId = examples.first.contestId;

      expect(await repo.listForContest(contestId), hasLength(examples.length));
      expect(await repo.listForContest(core.Id.create()), isEmpty);
    });

    test('listForProfile returns the profile participations', () async {
      final first = examples.first;

      expect(await repo.listForProfile(first.participantProfileId), [first]);
    });

    test('listForRole returns the participations with that role', () async {
      final first = examples.first;
      final sameRole = examples.where((p) => p.roleId == first.roleId);

      expect(await repo.listForRole(first.roleId), unorderedEquals(sameRole));
      expect(await repo.listForRole(core.Id.create()), isEmpty);
    });

    test('save updates the row and bumps the revision', () async {
      final participation = core.ContestParticipation.fromJson({
        ...examples.first.toJson(),
        'retired_at_round': 3,
      });

      final saved = await repo.save(participation, metadata: metadata());

      expect(saved.revision, examples.first.revision + 1);
      expect((await repo.findById(saved.id))?.retiredAtRound, 3);
    });

    test('delete removes the participation and its team memberships', () async {
      final profile = await repository.participantProfileRepository.save(
        core.ParticipantProfile.fromJson({
          ...exampleRows('participant_profile').first,
          'id': core.Id.create().value,
          'revision': 0,
        }),
        metadata: metadata(),
      );
      final fresh = await repo.save(
        core.ContestParticipation.fromJson({
          ...examples.first.toJson(),
          'id': core.Id.create().value,
          'participant_profile_id': profile.id.value,
          'participant_number': 99,
          'scoring_uuid': 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
          'revision': 0,
        }),
        metadata: metadata(),
      );
      final memberships = repository.teamMembershipRepository;
      final membership = await memberships.save(
        core.TeamMembership.fromJson({
          ...exampleRows('team_membership').first,
          'id': core.Id.create().value,
          'contest_participation_id': fresh.id.value,
          'revision': 0,
        }),
        metadata: metadata(),
      );
      final before = await tombstones();

      expect(await repo.delete(fresh.id, metadata: metadata()), isTrue);

      expect(await repo.findById(fresh.id), isNull);
      expect(await memberships.findById(membership.id), isNull);
      expect(await tombstones(), before + 2);
    });
  });
}
