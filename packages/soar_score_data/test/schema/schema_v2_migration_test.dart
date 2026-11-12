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
    },
    beforeOpen: (_) async {
      if (executor.dialect == SqlDialect.sqlite) {
        await customStatement('PRAGMA foreign_keys = ON');
      }
    },
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
              'ImportProvenance',
            };
            final stores = EntityStores.forDatabase(old);
            for (final (type, file) in exampleEntities) {
              if (!preservedTypes.contains(type)) continue;
              for (final row in exampleRows(file)) {
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
            final before =
                (await old
                        .customSelect(
                          'SELECT COUNT(*) AS n FROM mutation_records',
                        )
                        .getSingle())
                    .read<int>('n');
            expect(before, greaterThan(0));
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
            final scoresAfter = await upgraded
                .customSelect('SELECT * FROM official_scores ORDER BY id')
                .get();
            expect(
              [for (final row in scoresAfter) row.data],
              [for (final row in scoresBefore) row.data],
            );
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
