import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/example_entities.dart';
import '../support/example_rows.dart';
import '../support/fixtures.dart';

/// Recreates the version 1 schema, before pilot links were introduced.
class _Version1Database extends SoarScoreDatabase {
  _Version1Database(super.executor, {required super.profile});

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      final dialect = executor.dialect == SqlDialect.sqlite
          ? 'sqlite'
          : 'postgres';
      final statements = await File('schema_snapshots/v1_$dialect.sql')
          .readAsLines();
      final tables = {for (final t in profileTables) t.actualTableName};
      for (final sql in statements) {
        final table =
            RegExp(r'^CREATE TABLE IF NOT EXISTS "([^"]+)"')
                .firstMatch(sql)
                ?.group(1) ??
            RegExp(
              r'\bON\s+"?([a-z_]+)"?',
              caseSensitive: false,
            ).firstMatch(sql)?.group(1);
        if (table == null)
          throw StateError('Unrecognized snapshot statement: $sql');
        if (tables.contains(table)) await m.database.customStatement(sql);
      }
      // The test writes rows through the current model, which has the
      // aggregate column; the test drops it again before upgrading.
      await m.database.customStatement(
        'ALTER TABLE mutation_records ADD COLUMN aggregate_id TEXT',
      );
      await _accountColumn(m.database, add: true);
    },
    beforeOpen: (_) async {
      if (executor.dialect == SqlDialect.sqlite) {
        await customStatement('PRAGMA foreign_keys = ON');
      }
    },
  );
}

/// Adds or drops `accounts.profile_refreshed_at` on a version 1 database: the
/// test writes through the current model, which has the column, and drops it
/// again so that the upgrade has to add it. Only the server profile has the
/// table.
Future<void> _accountColumn(GeneratedDatabase db, {required bool add}) async {
  final sqlite = db.executor.dialect == SqlDialect.sqlite;
  final table = await db
      .customSelect(
        sqlite
            ? "SELECT 1 AS x FROM sqlite_master WHERE type = 'table' AND name = 'accounts'"
            : "SELECT 1 AS x FROM information_schema.tables WHERE table_schema = current_schema() AND table_name = 'accounts'",
      )
      .get();
  if (table.isEmpty) return;
  await db.customStatement(
    add
        ? 'ALTER TABLE accounts ADD COLUMN profile_refreshed_at TEXT'
        : 'ALTER TABLE accounts DROP COLUMN profile_refreshed_at',
  );
}

void main() => forEachBackend((backend) {
  for (final databaseProfile in DatabaseProfile.values) {
    for (final existingTable in [false, true]) {
      test(
        '${databaseProfile.name} upgrades version 1 with ${existingTable ? 'existing' : 'no'} link table without losing data',
        () async {
          final temp = await Directory.systemTemp.createTemp(
            'soar-migration-test-',
          );
          pg.Connection? admin;
          String? databaseName;
          SoarScoreDatabase? openDatabase;
          QueryExecutor openExecutor() {
            if (backend == Backend.sqlite) {
              return NativeDatabase(File('${temp.path}/legacy.sqlite'));
            }
            return postgresConfig!.named(databaseName!).toPgDatabase();
          }

          try {
            if (backend == Backend.postgres) {
              databaseName =
                  'soar_migration_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 24)}';
              admin = await pg.Connection.open(
                postgresConfig!.named('postgres').toEndpoint(),
                settings: postgresConfig!.toSettings(),
              );
              await admin.execute('CREATE DATABASE "$databaseName"');
            }
            final old = _Version1Database(
              openExecutor(),
              profile: databaseProfile,
            );
            openDatabase = old;
            const preservedTypes = {
              'Contest',
              'LandingTable',
              'LandingResult',
              'DisciplineProfile',
              'DisciplineConfigField',
              'DisciplineScoreField',
              'DisciplineValidation',
              'DisciplineFormula',
              'DisciplineRule',
              'ContestConfigurationPreset',
              'ContestConfigurationRevision',
              'ParticipantProfile',
              'Role',
              'ContestParticipation',
              'MatrixRevision',
              'Round',
              'RoundGroup',
              'ReFlight',
              'MatrixAssignment',
              'ScorePlaceholder',
              'ScoreAttempt',
              'OfficialScore',
              // A derived row that points at an official score, so the
              // rebuild of official_scores meets a real referrer.
              'FlightResult',
              'ImportProvenance',
            };
            final stores = EntityStores.forDatabase(old);
            for (final (type, file) in exampleEntities) {
              if (!preservedTypes.contains(type)) continue;
              for (final row in exampleRows(file)) {
                if (type == 'ScorePlaceholder') {
                  // Version 1 has no current-attempt column; the upgrade
                  // fills it, so write the version 1 columns only.
                  await old.customInsert(
                    'INSERT INTO score_placeholders (id, contest_id, '
                    'contest_participation_id, assignment_id, state, '
                    'score_revision, locked_by, locked_at, revision) '
                    'VALUES (${[for (var i = 1; i <= 9; i++) backend == Backend.sqlite ? '?' : '\$$i'].join(', ')})',
                    variables: [
                      for (final key in const [
                        'id',
                        'contest_id',
                        'contest_participation_id',
                        'assignment_id',
                        'state',
                        'score_revision',
                        'locked_by',
                        'locked_at',
                        'revision',
                      ])
                        Variable(row[key]),
                    ],
                  );
                  continue;
                }
                if (type == 'OfficialScore') {
                  // Version 1 has no selection origin and every score names
                  // the director who made it official.
                  const keys = [
                    'id',
                    'contest_id',
                    'score_placeholder_id',
                    'score_attempt_id',
                    'score_revision',
                    'components',
                    'set_at',
                    'set_by',
                    'reason',
                  ];
                  await old.customInsert(
                    'INSERT INTO official_scores (${keys.join(', ')}) '
                    'VALUES (${[for (var i = 1; i <= keys.length; i++) backend == Backend.sqlite ? '?' : '\$$i'].join(', ')})',
                    variables: [
                      for (final key in keys)
                        Variable(
                          key == 'components'
                              ? jsonEncode(row[key])
                              : key == 'set_by'
                              ? row[key] ??
                                    '019c0000-0000-7000-8000-000000000001'
                              : row[key],
                        ),
                    ],
                  );
                  continue;
                }
                await stores.of(type).upsertJson(row);
              }
            }
            final scoresBefore = await old
                .customSelect('SELECT * FROM official_scores ORDER BY id')
                .get();
            expect(scoresBefore, isNotEmpty);
            final owner = core.Id.create();
            final participantId = core.Id.create();
            final now = DateTime.utc(2026);
            final profile = core.ParticipantProfile(
              id: participantId,
              ownerAccountId: owner,
              firstName: 'Migration',
              lastName: 'Pilot',
              createdAt: now,
              updatedAt: now,
            );
            await Repository(old).participantProfileRepository
                .save(profile, metadata: metadata());
            final oldContest = contest(name: 'Preserved contest');
            await Repository(old).contestRepository
                .save(oldContest, metadata: metadata());
            // Two pending changes of one entity written before the fix, with
            // the timestamps Dart wrote: the earlier one reads ...00.584Z and
            // sorts after ...00.584005Z as text. Raw rows, so the current
            // write mapper cannot hide the legacy form.
            for (final (name, time, revision) in [
              ('legacy-a', '2026-05-01T12:00:00.584Z', 1),
              ('legacy-b', '2026-05-01T12:00:00.584005Z', 2),
            ]) {
              await old.customStatement(
                'INSERT INTO mutation_records (id, contest_id, '
                'owner_account_id, sequence, entity_type, entity_id, '
                'base_revision, client_mutation_id, actor_id, authority, '
                'source_installation_id, source_device, client_time, '
                'server_acceptance_time, server_rejection_time, payload, '
                'outcome, reason_code, error_message, '
                'depends_on_mutation_id) '
                "SELECT '${core.Id.create()}', contest_id, owner_account_id, "
                "NULL, entity_type, entity_id, $revision, '$name', actor_id, "
                "authority, source_installation_id, source_device, '$time', "
                'NULL, NULL, payload, \'Pending\', NULL, NULL, NULL '
                "FROM mutation_records WHERE contest_id = '${oldContest.id}' "
                'LIMIT 1',
              );
            }
            final before =
                (await old
                        .customSelect(
                          'SELECT COUNT(*) AS n FROM mutation_records',
                        )
                        .getSingle())
                    .read<int>('n');
            expect(before, greaterThan(0));
            // Back to the genuine version 1 shape: the upgrade adds the column.
            await old.customStatement(
              'ALTER TABLE mutation_records DROP COLUMN aggregate_id',
            );
            await _accountColumn(old, add: false);
            await old.customStatement(
              'CREATE TABLE pilot_import_links (unexpected TEXT)',
            );
            await old.customStatement(
              "INSERT INTO pilot_import_links (unexpected) VALUES ('keep me')",
            );
            await old.close();
            openDatabase = null;

            final refused = SoarScoreDatabase(
              openExecutor(),
              profile: databaseProfile,
            );
            openDatabase = refused;
            await expectLater(
              refused.doWhenOpened((_) {}),
              throwsA(isA<StateError>()),
            );
            await refused.close();
            openDatabase = null;
            final stillOld = _Version1Database(
              openExecutor(),
              profile: databaseProfile,
            );
            openDatabase = stillOld;
            await stillOld.customStatement(
              'ALTER TABLE mutation_records ADD COLUMN aggregate_id TEXT',
            );
            await _accountColumn(stillOld, add: true);
            expect(
              (await Repository(stillOld).participantProfileRepository
                      .findById(participantId))
                  ?.firstName,
              'Migration',
            );
            expect(
              (await stillOld
                      .customSelect('SELECT unexpected FROM pilot_import_links')
                      .getSingle())
                  .read<String>('unexpected'),
              'keep me',
            );
            expect(
              (await stillOld
                      .customSelect(
                        'SELECT COUNT(*) AS n FROM mutation_records',
                      )
                      .getSingle())
                  .read<int>('n'),
              before,
            );
            await stillOld.customStatement('DROP TABLE pilot_import_links');
            if (existingTable) {
              final dialect = backend == Backend.sqlite ? 'sqlite' : 'postgres';
              final definitions = await File('schema_snapshots/v2_$dialect.sql')
                  .readAsLines();
              final ddl = definitions.singleWhere(
                (line) => line.startsWith(
                  'CREATE TABLE IF NOT EXISTS "pilot_import_links"',
                ),
              );
              await stillOld.customStatement(ddl);
              await Repository(stillOld).pilotImportLinkRepository.save(
                core.PilotImportLink(
                  id: core.Id.create(),
                  ownerAccountId: owner,
                  sourcePilotNo: 7,
                  participantProfileId: participantId,
                  sourceValues: const {'firstName': 'migration'},
                  createdAt: now,
                  updatedAt: now,
                ),
                metadata: metadata(),
              );
            }
            await stillOld.customStatement(
              'ALTER TABLE mutation_records DROP COLUMN aggregate_id',
            );
            await _accountColumn(stillOld, add: false);
            await stillOld.close();
            openDatabase = null;

            final upgraded = SoarScoreDatabase(
              openExecutor(),
              profile: databaseProfile,
            );
            openDatabase = upgraded;
            final repository = Repository(upgraded);
            expect(
              (await repository.participantProfileRepository.findById(
                participantId,
              ))?.firstName,
              'Migration',
            );
            expect(
              (await repository.contestRepository.findById(oldContest.id))
                  ?.name,
              'Preserved contest',
            );
            expect(
              (await upgraded
                      .customSelect(
                        'SELECT COUNT(*) AS n FROM mutation_records '
                        'WHERE aggregate_id IS NOT NULL',
                      )
                      .getSingle())
                  .read<int>('n'),
              0,
            );
            // The legacy timestamps read in time order after the upgrade.
            final queued = await DriftSyncStore(upgraded)
                .pendingMutations(core.ContestScopeKey(oldContest.id));
            expect(
              [
                for (final m in queued)
                  if (m.clientMutationId.startsWith('legacy-'))
                    m.clientMutationId,
              ],
              ['legacy-a', 'legacy-b'],
            );
            final scoresAfter = await upgraded
                .customSelect('SELECT * FROM official_scores ORDER BY id')
                .get();
            // Every version 1 score was selected by a director: it reads
            // Manual, and nothing else about the row changes.
            expect(
              [
                for (final row in scoresAfter)
                  {...row.data}..remove('selection_origin'),
              ],
              [for (final row in scoresBefore) row.data],
            );
            expect(
              (await upgraded
                      .customSelect('SELECT COUNT(*) AS n FROM flight_results')
                      .getSingle())
                  .read<int>('n'),
              greaterThan(0),
            );
            expect(
              {for (final row in scoresAfter) row.data['selection_origin']},
              {'Manual'},
            );
            expect(
              (await upgraded
                      .customSelect(
                        'SELECT COUNT(*) AS n FROM score_placeholders '
                        'WHERE review_closed_score_revision IS NOT NULL',
                      )
                      .getSingle())
                  .read<int>('n'),
              0,
            );
            final unfilled = await upgraded
                .customSelect(
                  'SELECT COUNT(*) AS n FROM score_placeholders '
                  'WHERE score_revision > 0 AND current_attempt_id IS NULL',
                )
                .getSingle();
            expect(unfilled.read<int>('n'), 0);
            final wrong = await upgraded
                .customSelect(
                  'SELECT COUNT(*) AS n FROM score_placeholders p '
                  'JOIN official_scores o ON o.score_placeholder_id = p.id '
                  'AND o.score_revision = p.score_revision '
                  'WHERE p.current_attempt_id <> o.score_attempt_id',
                )
                .getSingle();
            expect(wrong.read<int>('n'), 0);
            expect(
              (await upgraded
                      .customSelect(
                        'SELECT COUNT(*) AS n FROM mutation_records',
                      )
                      .getSingle())
                  .read<int>('n'),
              before + (existingTable ? 1 : 0),
            );
            expect(
              await repository.pilotImportLinkRepository.listForOwner(owner),
              hasLength(existingTable ? 1 : 0),
            );
            final link = core.PilotImportLink(
              id: core.Id.create(),
              ownerAccountId: owner,
              sourcePilotNo: 1,
              participantProfileId: participantId,
              sourceValues: const {},
              createdAt: now,
              updatedAt: now,
            );
            await repository.pilotImportLinkRepository.save(
              link,
              metadata: metadata(),
            );
            expect(
              await repository.pilotImportLinkRepository.listForOwner(owner),
              hasLength(existingTable ? 2 : 1),
            );
            await upgraded.close();
            openDatabase = null;

            final reopened = SoarScoreDatabase(
              openExecutor(),
              profile: databaseProfile,
            );
            openDatabase = reopened;
            expect(
              await Repository(reopened).pilotImportLinkRepository
                  .listForOwner(owner),
              hasLength(existingTable ? 2 : 1),
            );
            await reopened.close();
            openDatabase = null;
          } finally {
            await openDatabase?.close();
            if (admin != null && databaseName != null) {
              await admin.execute('DROP DATABASE "$databaseName" WITH (FORCE)');
              await admin.close();
            }
            await temp.delete(recursive: true);
          }
        },
      );
    }
  }
});
