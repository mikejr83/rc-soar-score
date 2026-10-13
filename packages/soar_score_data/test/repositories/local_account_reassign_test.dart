import 'package:drift/drift.dart' show DriftSqlType, Variable;
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  // Only an installation has a Local account.
  final skip = backend == Backend.postgres
      ? 'client-only table, not on the server'
      : false;

  late Installation inst;
  late LocalAccountRepository local;
  late core.Id localId;
  final account = core.Id.create();

  setUp(() async {
    inst = await Installation.open(backend);
    if (backend == Backend.sqlite) {
      local = LocalAccountRepository(inst.db);
      localId = await local.ensure();
      await SystemDataSeeder(inst.db).seed();
    }
  });
  tearDown(() => inst.close());

  /// How many text values in [tables] (all of them when null) contain [id],
  /// by table and column, leaving out the Local account row itself.
  Future<Map<String, int>> occurrences(core.Id id) async {
    final found = <String, int>{};
    for (final table in inst.db.profileTables) {
      final name = table.actualTableName;
      if (name == 'local_account') continue;
      for (final column in table.$columns) {
        if (column.type != DriftSqlType.string) continue;
        final n =
            (await inst.db
                    .customSelect(
                      'SELECT COUNT(*) AS n FROM $name WHERE ${column.name} LIKE ?',
                      variables: [Variable.withString('%${id.value}%')],
                    )
                    .getSingle())
                .read<int>('n');
        if (n > 0) found['$name.${column.name}'] = n;
      }
    }
    return found;
  }

  group('reassignTo', () {
    test('re-points the whole demo database', skip: skip, () async {
      await DemoDataSeeder(Repository(inst.db), localAccountId: localId).seed();
      final before = await occurrences(localId);
      expect(before, isNotEmpty);
      expect(await occurrences(account), isEmpty);

      await local.reassignTo(account);

      expect(await occurrences(localId), isEmpty);
      expect(await occurrences(account), before);
      expect(await local.find(), localId, reason: 'the Local id is kept');
    });

    test('keeps a pending mutation valid', skip: skip, () async {
      final saved = await inst.unitOfWork.run(
        (c) => c.save(
          core.Contest(
            id: core.Id.create(),
            name: 'Offline Meet',
            startDateTime: DateTime.utc(2026, 4, 15, 10),
            endDateTime: DateTime.utc(2026, 4, 16, 20),
            timezone: 'America/Denver',
            ownerAccountId: localId,
            createdAt: DateTime.utc(2026, 4),
            updatedAt: DateTime.utc(2026, 4),
          ),
          metadata: core.MutationMetadata(
            clientMutationId: 'request-claim',
            authority: core.Authority.director,
            clientTime: DateTime.utc(2026, 5, 1, 11),
            actorId: localId,
          ),
        ),
      );

      await local.reassignTo(account);

      final pending = (await inst.syncStore.pendingMutations(
        core.ContestScopeKey(saved.id),
      )).single;
      expect(pending.actorId, account);
      expect(pending.payload.toString(), isNot(contains(localId.value)));
      expect(pending.payload.toString(), contains(account.value));
      expect(pending.clientMutationId, 'request-claim');
      final contest = await ContestRepository(inst.db).findById(saved.id);
      expect(contest!.ownerAccountId, account);
    });

    test('leaves text that merely contains the id alone', skip: skip, () async {
      final note = 'see ${localId.value}';
      final saved = await inst.unitOfWork.run(
        (c) => c.save(
          core.Contest(
            id: core.Id.create(),
            name: note,
            startDateTime: DateTime.utc(2026, 4, 15, 10),
            endDateTime: DateTime.utc(2026, 4, 16, 20),
            timezone: 'America/Denver',
            ownerAccountId: localId,
            createdAt: DateTime.utc(2026, 4),
            updatedAt: DateTime.utc(2026, 4),
          ),
          metadata: metadata(),
        ),
      );

      await local.reassignTo(account);

      final pending = (await inst.syncStore.pendingMutations(
        core.ContestScopeKey(saved.id),
      )).single;
      final data = pending.payload['data']! as Map;
      final entity = data['entity']! as Map;
      expect(entity['name'], note);
      expect(entity['owner_account_id'], account.value);
    });

    test('moves a director scope position', skip: skip, () async {
      await inst.db.customStatement(
        "INSERT INTO local_sync_positions (scope_kind, scope_id, "
        "last_synced_sequence) VALUES ('Director', '${localId.value}', 4)",
      );

      await local.reassignTo(account);

      expect(
        await inst.syncStore.readCursor(core.DirectorScopeKey(account)),
        4,
      );
      expect(
        await inst.syncStore.readCursor(core.DirectorScopeKey(localId)),
        0,
      );
    });

    test('keeps the position the account already has', skip: skip, () async {
      for (final (id, sequence) in [(localId, 2), (account, 9)]) {
        await inst.db.customStatement(
          "INSERT INTO local_sync_positions (scope_kind, scope_id, "
          "last_synced_sequence) VALUES ('Director', '${id.value}', $sequence)",
        );
      }

      await local.reassignTo(account);

      expect(
        await inst.syncStore.readCursor(core.DirectorScopeKey(account)),
        9,
      );
      expect(
        await inst.syncStore.readCursor(core.DirectorScopeKey(localId)),
        0,
        reason: 'the Local position is dropped',
      );
    });

    test('is idempotent', skip: skip, () async {
      await DemoDataSeeder(Repository(inst.db), localAccountId: localId).seed();
      await local.reassignTo(account);
      final once = await occurrences(account);

      await local.reassignTo(account);

      expect(await occurrences(account), once);
      expect(await occurrences(localId), isEmpty);
    });

    test('leaves other accounts alone', skip: skip, () async {
      final other = core.Id.create();
      await DemoDataSeeder(Repository(inst.db), localAccountId: other).seed();
      final before = await occurrences(other);

      await local.reassignTo(account);

      expect(await occurrences(other), before);
      expect(await occurrences(account), isEmpty);
    });

    test('refuses the Local account itself', skip: skip, () async {
      await expectLater(local.reassignTo(localId), throwsArgumentError);
    });

    test('needs the Local account to exist', skip: skip, () async {
      final fresh = await Installation.open(backend);
      addTearDown(fresh.close);
      await expectLater(
        LocalAccountRepository(fresh.db).reassignTo(account),
        throwsStateError,
      );
    });

    test('changes nothing when one update fails', skip: skip, () async {
      Future<void> role(core.Id owner) => inst.unitOfWork.run(
        (c) => c.save(
          core.Role(
            id: core.Id.create(),
            ownerAccountId: owner,
            displayName: 'Timekeeper',
            type: core.RoleType.nonFlier,
          ),
          metadata: metadata(),
        ),
      );
      // The account already has a role of the same name, which the owner and
      // name index forbids a second time.
      await role(localId);
      await role(account);
      final before = await occurrences(localId);

      await expectLater(local.reassignTo(account), throwsA(anything));

      expect(await occurrences(localId), before);
    });
  });

  test('every account column is reassigned or exempt', skip: skip, () async {
    final accountLike = RegExp(
      r'(account_id|actor_id|_by$|^owner_account_id$|actor)',
    );
    final listed = {
      for (final MapEntry(key: table, value: columns)
          in localAccountReferences.entries)
        for (final column in columns) '$table.$column',
    };
    final missing = <String>[];
    for (final table in inst.db.profileTables) {
      for (final column in table.$columns) {
        final name = '${table.actualTableName}.${column.name}';
        if (accountLike.hasMatch(column.name) &&
            !listed.contains(name) &&
            !accountColumnsNotReassigned.containsKey(name) &&
            !_notAccounts.contains(name)) {
          missing.add(name);
        }
      }
    }
    expect(
      missing,
      isEmpty,
      reason:
          'list each in localAccountReferences or accountColumnsNotReassigned',
    );
    for (final name in listed) {
      final (table, column) = (name.split('.')[0], name.split('.')[1]);
      expect(
        inst.db.profileTables.any(
          (t) =>
              t.actualTableName == table &&
              t.$columns.any((c) => c.name == column),
        ),
        isTrue,
        reason: '$name is listed but not in the schema',
      );
    }
  });
}

/// Columns whose names look like account references but hold something else.
const _notAccounts = {
  're_flight_participants.responded_by', // a role, not an account
  'discipline_profiles.superseded_by', // a profile version
  'matrix_assignments.superseded_by_assignment_id', // an assignment
  'rounds.superseded_by_round_id', // a round
};
