import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  late ContestRepository contests;
  final owner = core.Id.create();

  setUp(() async {
    inst = await Installation.open(backend);
    contests = ContestRepository(inst.db);
  });
  tearDown(() => inst.close());

  test('saves the sample contests into an empty database', () async {
    final saved = await DemoContestSeeder(
      contests,
      localAccountId: owner,
    ).seed();

    final stored = await contests.getAll();
    expect(saved, 3);
    expect(stored, hasLength(3));
    expect(
      stored.map((contest) => contest.ownerAccountId),
      everyElement(owner),
    );
    final mutations = await inst.db
        .customSelect('SELECT actor_id FROM mutation_records')
        .get();
    expect(
      mutations.map((row) => row.read<String>('actor_id')),
      everyElement(owner.value),
    );
  });

  test('is idempotent', () async {
    final seeder = DemoContestSeeder(contests, localAccountId: owner);
    await seeder.seed();
    final first = await contests.getAll();

    expect(await seeder.seed(), 0);
    expect(await contests.getAll(), first);
  });

  test('leaves a database that already holds contests alone', () async {
    final existing = core.Contest(
      id: core.Id.create(),
      name: 'My own contest',
      startDateTime: DateTime.utc(2026, 12, 1, 14),
      endDateTime: DateTime.utc(2026, 12, 1, 22),
      timezone: 'America/Denver',
      createdAt: DateTime.utc(2026, 9),
      updatedAt: DateTime.utc(2026, 9),
    );
    await contests.save(
      existing,
      metadata: core.MutationMetadata(
        clientMutationId: 'test',
        authority: core.Authority.director,
        clientTime: DateTime.utc(2026, 9),
      ),
    );

    expect(await DemoContestSeeder(contests, localAccountId: owner).seed(), 0);
    expect((await contests.getAll()).map((contest) => contest.name), [
      'My own contest',
    ]);
  });
}
