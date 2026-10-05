import 'package:drift/drift.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart' show portableSql;
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  setUp(() async => inst = await Installation.open(backend));
  tearDown(() => inst.close());

  Future<void> insert({
    String? contest,
    String? owner,
    String client = 'r1',
    String outcome = 'Pending',
    int? sequence,
  }) => inst.db.customInsert(
    portableSql(
      inst.db,
      'INSERT INTO mutation_records (id, contest_id, owner_account_id, '
      'sequence, entity_type, entity_id, client_mutation_id, authority, '
      "client_time, payload, outcome) VALUES (?, ?, ?, ?, 'Contest', ?, ?, "
      "'Director', '2026-05-01T11:00:00Z', '{}', ?)",
    ),
    variables: [
      Variable(core.Id.create().value),
      Variable(contest),
      Variable(owner),
      Variable(sequence),
      Variable(core.Id.create().value),
      Variable(client),
      Variable(outcome),
    ],
  );

  final contestId = core.Id.create().value;
  final ownerId = core.Id.create().value;

  group('mutation_records', () {
    test('needs exactly one scope', () async {
      await insert(contest: contestId);
      await insert(owner: ownerId, client: 'r2');
      await expectLater(insert(client: 'r3'), throwsA(anything));
      await expectLater(
        insert(contest: contestId, owner: ownerId, client: 'r4'),
        throwsA(anything),
      );
    });

    test('a client mutation id is unique within its scope only', () async {
      await insert(contest: contestId);
      await expectLater(insert(contest: contestId), throwsA(anything));
      await insert(contest: core.Id.create().value);
      await insert(owner: ownerId);
    });

    test('a sequence belongs to an accepted mutation and is unique', () async {
      await expectLater(
        insert(contest: contestId, sequence: 1),
        throwsA(anything),
      );
      await insert(contest: contestId, outcome: 'Accepted', sequence: 1);
      await expectLater(
        insert(
          contest: contestId,
          client: 'r2',
          outcome: 'Accepted',
          sequence: 1,
        ),
        throwsA(anything),
      );
    });

    test('rejects an outcome that is not documented', () async {
      await expectLater(
        insert(contest: contestId, outcome: 'accepted'),
        throwsA(anything),
      );
    });
  });
}
