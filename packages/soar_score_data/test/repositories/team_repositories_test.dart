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

  final teams = [
    for (final row in exampleRows('team')) core.Team.fromJson(row),
  ];
  final memberships = [
    for (final row in exampleRows('team_membership'))
      core.TeamMembership.fromJson(row),
  ];

  group('TeamRepository', () {
    late core.TeamRepository repo;
    setUp(() => repo = repository.teamRepository);

    test('reads back the example teams unchanged', () async {
      for (final team in teams) {
        expect(await repo.findById(team.id), team);
      }
    });

    test('listForContest returns the teams by name', () async {
      final byName = [...teams]..sort((a, b) => a.name.compareTo(b.name));

      expect(await repo.listForContest(teams.first.contestId), byName);
      expect(await repo.listForContest(core.Id.create()), isEmpty);
    });

    test('save renames the team and bumps the revision', () async {
      final renamed = core.Team.fromJson({
        ...teams.first.toJson(),
        'name': 'Renamed',
      });

      final saved = await repo.save(renamed, metadata: metadata());

      expect(saved.revision, teams.first.revision + 1);
      expect((await repo.findById(saved.id))?.name, 'Renamed');
    });

    test('delete removes the team and its memberships together', () async {
      final team = await repo.save(
        core.Team.fromJson({
          ...teams.first.toJson(),
          'id': core.Id.create().value,
          'name': 'Disposable',
          'revision': 0,
        }),
        metadata: metadata(),
      );
      final membershipRepo = repository.teamMembershipRepository;
      for (final source in memberships.take(2)) {
        await membershipRepo.save(
          core.TeamMembership.fromJson({
            ...source.toJson(),
            'id': core.Id.create().value,
            'team_id': team.id.value,
            'revision': 0,
          }),
          metadata: metadata(),
        );
      }
      final before = await inst.count('tombstones');

      expect(await repo.delete(team.id, metadata: metadata()), isTrue);

      expect(await repo.findById(team.id), isNull);
      expect(await membershipRepo.listForTeam(team.id), isEmpty);
      expect(await inst.count('tombstones'), before + 3);
      expect(await repo.delete(team.id, metadata: metadata()), isFalse);
    });
  });

  group('TeamMembershipRepository', () {
    late core.TeamMembershipRepository repo;
    setUp(() => repo = repository.teamMembershipRepository);

    test('reads back the example memberships unchanged', () async {
      for (final membership in memberships) {
        expect(await repo.findById(membership.id), membership);
      }
    });

    test('listForTeam and listForContest filter the memberships', () async {
      final team = teams.first;

      expect(
        await repo.listForTeam(team.id),
        unorderedEquals(memberships.where((m) => m.teamId == team.id)),
      );
      expect(
        await repo.listForContest(team.contestId),
        hasLength(memberships.length),
      );
    });

    test('save then delete a membership', () async {
      final membership = memberships.first;
      final moved = core.TeamMembership.fromJson({
        ...membership.toJson(),
        'team_id': teams.last.id.value,
      });

      final saved = await repo.save(moved, metadata: metadata());
      expect(saved.revision, membership.revision + 1);
      expect((await repo.findById(membership.id))?.teamId, teams.last.id);

      expect(await repo.delete(membership.id, metadata: metadata()), isTrue);
      expect(await repo.findById(membership.id), isNull);
    });
  });
}
