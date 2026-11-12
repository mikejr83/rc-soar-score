import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;

import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import 'exchange_support.dart';

const _autumn = 'Autumn F5J Classic';
const _mountain = 'Mountain States Team F5J';

void main() {
  late Site source;
  late Site target;

  setUp(() async {
    source = await Site.open(demo: true);
    target = await Site.open();
  });
  tearDown(() async {
    await source.close();
    await target.close();
  });

  Future<ImportResult> importInspection(
    ExchangeFile file, {
    Site? into,
    String? fileName,
  }) {
    final site = into ?? target;
    return site.importer.import(
      file,
      mode: ImportMode.inspection,
      target: site.target,
      fileName: fileName,
    );
  }

  group('export', () {
    test(
      'writes the contest, the director rows it uses and diagnostics',
      () async {
        final file = await source.exportNamed(
          _autumn,
          source: const ExportSource(
            installationId: 'install-1',
            appVersion: '1.2.3',
            label: 'Director Dana',
            diagnostics: {'platform': 'windows', 'signed_in': false},
          ),
        );
        final header = file.header;
        expect(header.formatVersion, exchangeFormatVersion);
        expect(header.schemaVersion, source.db.schemaVersion);
        expect(header.contestName, _autumn);
        expect(header.sourceOwnerKind, SourceOwnerKind.local);
        expect(header.sourceSyncState, SourceSyncState.never);
        expect(header.sourceAccountId, source.localId.value);
        expect(header.sourceLocalAccountId, source.localId.value);
        expect(header.sourceInstallationId, 'install-1');
        expect(header.appVersion, '1.2.3');
        expect(header.redacted, isFalse);
        expect(header.systemReferences, isNotEmpty);

        expect(file.rows('contests').single['name'], _autumn);
        expect(file.rows('contest_participations'), hasLength(8));
        expect(file.rows('participant_profiles'), hasLength(8));
        expect(file.rows('official_scores'), isNotEmpty);
        expect(file.rows('mutation_records'), isNotEmpty);
        // Derived rows are only diagnostics; system rows are not exported.
        expect(file.tables.keys, isNot(contains('participation_standings')));
        expect(file.tables.keys, isNot(contains('discipline_profiles')));
        final seen = file.diagnostics['derived_as_seen'] as Map;
        expect((seen['participation_standings'] as List), isNotEmpty);
        expect((seen['flight_results'] as List), isNotEmpty);
        expect(file.diagnostics['app'], {
          'platform': 'windows',
          'signed_in': false,
        });
        final sync = file.diagnostics['sync'] as Map;
        expect(sync['pending_mutations'], greaterThan(0));
        expect(sync['rejected_mutations'], 0);
      },
    );

    test('only holds rows of the contest', () async {
      final file = await source.exportNamed(_autumn);
      final contest = file.header.contestId;
      for (final spec in contestExchangeTables.skip(1)) {
        for (final row in file.rows(spec.table)) {
          expect(
            row[spec.contestColumn] ?? contest,
            contest,
            reason: spec.table,
          );
        }
      }
      final other = await source.exportNamed(_mountain);
      expect(
        {for (final r in file.rows('official_scores')) r['id']}.intersection({
          for (final r in other.rows('official_scores')) r['id'],
        }),
        isEmpty,
      );
    });

    test('names who owned the contest and whether it ever synced', () async {
      final contest = await source.contestNamed(_autumn);
      final account = core.Id.create();
      Future<void> setOwner(String? owner) => source.db.customStatement(
        'UPDATE contests SET owner_account_id = ${owner == null ? 'NULL' : "'$owner'"} '
        "WHERE id = '${contest.id.value}'",
      );

      await setOwner(account.value);
      var header = (await source.exportNamed(_autumn)).header;
      expect(header.sourceOwnerKind, SourceOwnerKind.account);
      expect(header.sourceSyncState, SourceSyncState.unknown);

      await source.db.customStatement(
        "INSERT INTO local_sync_positions (scope_kind, scope_id, last_synced_sequence) "
        "VALUES ('Contest', '${contest.id.value}', 7)",
      );
      header = (await source.exportNamed(_autumn)).header;
      expect(header.sourceSyncState, SourceSyncState.synced);

      await setOwner(null);
      header = (await source.exportNamed(_autumn)).header;
      expect(header.sourceOwnerKind, SourceOwnerKind.local);
      expect(header.sourceSyncState, SourceSyncState.never);
    });

    test('an accepted mutation also means the contest synced', () async {
      final contest = await source.contestNamed(_autumn);
      await source.db.customStatement(
        "UPDATE contests SET owner_account_id = '${core.Id.create().value}' "
        "WHERE id = '${contest.id.value}'",
      );
      await source.db.customStatement(
        "UPDATE mutation_records SET outcome = 'Accepted', sequence = 1 "
        "WHERE id = (SELECT id FROM mutation_records WHERE contest_id = "
        "'${contest.id.value}' LIMIT 1)",
      );
      final header = (await source.exportNamed(_autumn)).header;
      expect(header.sourceSyncState, SourceSyncState.synced);
    });

    test('refuses a contest that is not in the database', () async {
      await expectLater(
        source.exporter.export(core.Id.create()),
        throwsA(
          isA<ExchangeException>().having(
            (e) => e.code,
            'code',
            'contest_not_found',
          ),
        ),
      );
    });

    test('every table is classified, and the file holds the classed ones', () async {
      final tables = {
        for (final t in source.db.profileTables) t.actualTableName,
      };
      expect(
        exchangeClassByTable.keys.toSet().containsAll(tables),
        isTrue,
        reason:
            'unclassified: ${tables.difference(exchangeClassByTable.keys.toSet())}',
      );
      final file = await source.exportNamed(_autumn);
      expect(file.tables.keys.toSet(), {
        for (final entry in exchangeClassByTable.entries)
          if (entry.value == ExchangeClass.contest ||
              entry.value == ExchangeClass.director)
            entry.key,
      });
    });
  });

  group('redaction', () {
    test('removes contact details everywhere and nothing else', () async {
      final contest = await source.contestNamed(_autumn);
      final id = contest.id.value;
      const secret = 'dana.secret@example.test';
      await source.db.customStatement(
        "UPDATE participant_profiles SET email = '$secret'",
      );
      await source.db.customStatement(
        "UPDATE audit_events SET reason = 'wrote to $secret' "
        "WHERE contest_id = '$id'",
      );
      await source.db.customStatement(
        "UPDATE mutation_records SET error_message = 'cannot mail $secret', "
        "payload = '{\"version\":1,\"data\":{\"operation\":\"save\",\"entity\":"
        "{\"email\":\"$secret\"}}}' WHERE id = (SELECT id FROM mutation_records "
        "WHERE contest_id = '$id' LIMIT 1)",
      );
      final mutation = await source.db
          .customSelect(
            "SELECT id, entity_type, entity_id FROM mutation_records WHERE contest_id = '$id' LIMIT 1",
          )
          .getSingle();
      await source.db.customInsert(
        'INSERT INTO conflict_records (id, contest_id, entity_type, entity_id, '
        'competing_mutation_id, reason_code, reason, requires_action, '
        'resolution, created_at, accepted_payload, competing_payload) '
        "VALUES ('${core.Id.create().value}', '$id', 'Contest', '$id', "
        "'${mutation.read<String>('id')}', 'stale', 'see $secret', 1, "
        "'Pending', '2026-10-01T00:00:00Z', "
        "'{\"email\":\"$secret\"}', '{\"people\":[{\"Email\":\"$secret\"}]}')",
      );

      final plain = await source.exportNamed(_autumn);
      final redacted = await source.exportNamed(_autumn, redact: true);

      expect(utf8.decode(plain.encode()), contains(secret));
      expect(utf8.decode(redacted.encode()), isNot(contains(secret)));
      expect(redacted.header.redacted, isTrue);
      for (final profile in redacted.rows('participant_profiles')) {
        expect(profile['email'], isNull);
        expect(profile['last_name'], isNotNull);
      }

      // Ids, scores, revisions and timestamps are untouched.
      Object? strip(Object? node) => switch (node) {
        Map() => {
          for (final e in node.entries)
            if (!{
              'email',
              'reason',
              'error_message',
            }.contains(e.key.toString().toLowerCase()))
              e.key: strip(e.value),
        },
        List() => [for (final i in node) strip(i)],
        _ => node,
      };
      expect(strip(redacted.tables), strip(plain.tables));
      expect(
        jsonEncode(redacted.rows('official_scores')),
        jsonEncode(plain.rows('official_scores')),
      );
    });
  });

  group('inspection import', () {
    test('keeps every row, owned by one inspection owner', () async {
      final file = await source.exportNamed(_autumn);
      final preview = await target.importer.preview(
        file,
        target: target.target,
      );
      expect(preview.availableModes, [
        ImportMode.inspection,
        ImportMode.editable,
      ]);
      expect(preview.counts['participants'], 8);
      expect(preview.redacted, isFalse);

      final result = await importInspection(file, fileName: 'autumn.rcsoar');

      final owner = result.ownerId;
      expect(owner, isNot(target.localId));
      expect(owner, isNot(source.localId));
      final markers = await InspectionOwnerMarkers(target.db).load();
      expect(markers.contains(owner), isTrue);
      expect(markers.identitiesOf(owner.value), {source.localId.value});

      final contest = await target.contestNamed(_autumn);
      expect(contest.id.value, file.header.contestId);
      expect(contest.ownerAccountId, owner);

      // Rows are the file's, with the owner rewritten.
      final rewritten = rewriteAccountReferences(
        file.tables,
        from: file.header.sourceIdentities,
        to: owner.value,
      );
      for (final spec in [
        ...contestExchangeTables,
        ...directorExchangeTables,
      ]) {
        final key = spec.contestColumn == 'id' && spec.table != 'contests'
            ? null
            : file.header.contestId;
        if (key == null) continue;
        final stored = await rowsOf(target.db, spec, key);
        final expected = [...?rewritten[spec.table]]
          ..removeWhere(
            (r) => spec.table == 'mutation_records' && r['contest_id'] == null,
          );
        expect(
          jsonEncode(stored),
          jsonEncode(
            [...expected]..sort((a, b) => '${a['id']}'.compareTo('${b['id']}')),
          ),
          reason: spec.table,
        );
      }

      // No trace of the foreign Local account is left in live rows, other
      // than in the marker that records it.
      final traces = await occurrences(target.db, source.localId.value);
      expect(traces.keys.toSet(), {'audit_events.reason'});

      // Results recomputed here match what the director's app stored.
      expect(result.differences, isEmpty);
      expect(result.recalculationNote, isNull);
      expect(
        (await Repository(target.db).participationStandingRepository
                .listForContest(contest.id))
            .length,
        greaterThan(0),
      );
    });

    test('leaves the importing installation\'s own rows alone', () async {
      final own = core.Contest(
        id: core.Id.create(),
        name: 'My Own Meet',
        startDateTime: DateTime.utc(2026, 5, 1),
        endDateTime: DateTime.utc(2026, 5, 2),
        timezone: 'America/Denver',
        ownerAccountId: target.localId,
        createdAt: DateTime.utc(2026, 4),
        updatedAt: DateTime.utc(2026, 4),
      );
      await target.inst.unitOfWork.run(
        (c) => c.save(own, metadata: metadata()),
      );
      // An earlier claim left rows of the source's Local account here.
      final foreign = core.Contest(
        id: core.Id.create(),
        name: 'Claimed Earlier',
        startDateTime: DateTime.utc(2026, 5, 1),
        endDateTime: DateTime.utc(2026, 5, 2),
        timezone: 'America/Denver',
        ownerAccountId: source.localId,
        createdAt: DateTime.utc(2026, 4),
        updatedAt: DateTime.utc(2026, 4),
      );
      await target.inst.unitOfWork.run(
        (c) => c.save(foreign, metadata: metadata()),
      );

      await importInspection(await source.exportNamed(_autumn));

      final contests = {
        for (final c in await Repository(target.db).contestRepository.getAll())
          c.name: c.ownerAccountId,
      };
      expect(contests['My Own Meet'], target.localId);
      expect(contests['Claimed Earlier'], source.localId);
    });

    test('never changes the importing installation\'s Local account', () async {
      final before = await LocalAccountRepository(target.db).find();
      await importInspection(await source.exportNamed(_autumn));
      expect(await LocalAccountRepository(target.db).find(), before);
    });

    test(
      'refuses a contest that is already here, and changes nothing',
      () async {
        final file = await source.exportNamed(_autumn);
        await importInspection(file);
        final before = await occurrences(target.db, file.header.contestId);

        final preview = await target.importer.preview(
          file,
          target: target.target,
        );
        expect(preview.availableModes, isEmpty);
        expect(preview.refusals.single.code, 'contest_exists');
        expect(preview.existingCopyName, _autumn);
        await expectLater(
          importInspection(file),
          throwsA(isA<ImportRefusedException>()),
        );
        expect(await occurrences(target.db, file.header.contestId), before);
      },
    );

    test(
      'reuses one owner and the shared pilots for a second contest',
      () async {
        final first = await importInspection(await source.exportNamed(_autumn));
        final second = await importInspection(
          await source.exportNamed(_mountain),
        );
        expect(second.ownerId, first.ownerId);
        expect(second.reusedRows, greaterThan(0));
        final markers = await InspectionOwnerMarkers(target.db).load();
        expect(markers.ownerIds, {first.ownerId.value});
      },
    );

    test(
      'the same installation before and after sign-in is one owner',
      () async {
        final first = await importInspection(await source.exportNamed(_autumn));
        // The director signed in: the contest now belongs to an account, and
        // the export names both it and the Local account.
        final account = core.Id.create();
        final contest = await source.contestNamed(_mountain);
        await source.db.customStatement(
          "UPDATE contests SET owner_account_id = '${account.value}' "
          "WHERE id = '${contest.id.value}'",
        );
        final file = await source.exportNamed(_mountain);
        expect(file.header.sourceAccountId, account.value);
        expect(file.header.sourceLocalAccountId, source.localId.value);

        final second = await importInspection(file);
        expect(second.ownerId, first.ownerId);
        final markers = await InspectionOwnerMarkers(target.db).load();
        expect(markers.identitiesOf(first.ownerId.value), {
          source.localId.value,
          account.value,
        });
      },
    );

    test('unrelated sources get different owners', () async {
      final other = await Site.open();
      addTearDown(other.close);
      final meet = core.Contest(
        id: core.Id.create(),
        name: 'Someone Else\'s Meet',
        startDateTime: DateTime.utc(2026, 5, 1),
        endDateTime: DateTime.utc(2026, 5, 2),
        timezone: 'America/Denver',
        ownerAccountId: other.localId,
        createdAt: DateTime.utc(2026, 4),
        updatedAt: DateTime.utc(2026, 4),
      );
      await other.inst.unitOfWork.run(
        (c) => c.save(meet, metadata: metadata()),
      );
      final first = await importInspection(await source.exportNamed(_autumn));
      final second = await importInspection(
        await other.exportNamed('Someone Else\'s Meet'),
      );
      expect(second.ownerId, isNot(first.ownerId));
    });

    test('refuses when a director row here differs', () async {
      final file = await source.exportNamed(_autumn);
      final profile = file.rows('participant_profiles').first;
      await target.db.customStatement(
        "INSERT INTO participant_profiles (id, owner_account_id, first_name, "
        "last_name, created_at, updated_at) VALUES ('${profile['id']}', "
        "'${target.localId.value}', 'Someone', 'Else', "
        "'2026-01-01T00:00:00Z', '2026-01-01T00:00:00Z')",
      );
      final preview = await target.importer.preview(
        file,
        target: target.target,
      );
      for (final mode in ImportMode.values) {
        expect(
          preview.refusalsFor(mode).map((r) => r.code),
          contains('director_row_differs'),
        );
      }
      await expectLater(
        importInspection(file),
        throwsA(isA<ImportRefusedException>()),
      );
      expect(
        await countWhere(target.db, 'contests', 'id', file.header.contestId),
        0,
      );
    });

    test('refuses when the shipped rows it uses are missing', () async {
      final bare = await Site.open(system: false);
      addTearDown(bare.close);
      final file = await source.exportNamed(_autumn);
      final preview = await bare.importer.preview(file, target: bare.target);
      expect(
        preview.refusals.map((r) => r.code),
        contains('missing_system_row'),
      );
      expect(preview.availableModes, isEmpty);
    });

    test(
      'is atomic: a file with dangling references changes nothing',
      () async {
        final file = await source.exportNamed(_autumn);
        file.rows('score_attempts').first['matrix_revision_id'] =
            core.Id.create().value;
        await expectLater(
          importInspection(file),
          throwsA(
            isA<ExchangeException>().having(
              (e) => e.code,
              'code',
              'broken_references',
            ),
          ),
        );
        expect(
          await countWhere(target.db, 'contests', 'id', file.header.contestId),
          0,
        );
        expect(
          (await InspectionOwnerMarkers(target.db).load()).isEmpty,
          isTrue,
        );
        expect(
          await countWhere(target.db, 'participant_profiles', 'country', 'US'),
          0,
        );
      },
    );

    test('keeps rejected and conflicted mutations as they were', () async {
      final contest = await source.contestNamed(_autumn);
      await source.db.customStatement(
        "UPDATE mutation_records SET outcome = 'Rejected', reason_code = 'not_owner', "
        "server_rejection_time = '2026-10-01T00:00:00Z' WHERE id = "
        "(SELECT id FROM mutation_records WHERE contest_id = '${contest.id.value}' LIMIT 1)",
      );
      final file = await source.exportNamed(_autumn);
      expect((file.diagnostics['sync'] as Map)['rejected_mutations'], 1);
      await importInspection(file);
      final stored = await rowsOf(
        target.db,
        contestExchangeTables.firstWhere((t) => t.table == 'mutation_records'),
        file.header.contestId,
      );
      expect(stored.where((m) => m['outcome'] == 'Rejected'), hasLength(1));
      expect(stored.where((m) => m['outcome'] == 'Pending'), isNotEmpty);
    });

    test('reports results that differ from what the director saw', () async {
      final file = await source.exportNamed(_autumn);
      final seen = file.diagnostics['derived_as_seen'] as Map;
      final standings = seen['participation_standings'] as List;
      (standings.first as Map)['place'] = 99;
      standings.removeLast();
      final result = await importInspection(file);
      expect(
        result.differences.map((d) => d.kind),
        containsAll(['changed', 'extra']),
      );
      expect(result.differences.where((d) => d.column == 'place'), isNotEmpty);
    });
  });

  group('editable copy', () {
    test('is owned by the importing account with a provenance event', () async {
      final file = await source.exportNamed(_autumn);
      final preview = await target.importer.preview(
        file,
        target: target.target,
      );
      expect(preview.canImport(ImportMode.editable), isTrue);

      final result = await target.importer.import(
        file,
        mode: ImportMode.editable,
        target: target.target,
        fileName: 'autumn.rcsoar',
      );
      expect(result.ownerId, target.localId);
      final contest = await target.contestNamed(_autumn);
      expect(contest.ownerAccountId, target.localId);
      expect((await InspectionOwnerMarkers(target.db).load()).isEmpty, isTrue);
      expect((await occurrences(target.db, source.localId.value)).keys, [
        'audit_events.reason',
      ]);
      final events = await Repository(target.db).auditEventRepository
          .listForContest(contest.id, action: core.AuditAction.restoration);
      expect(events, hasLength(1));
      expect(jsonDecode(events.single.reason!)['file_name'], 'autumn.rcsoar');
    });

    test('carries the import stamps of the contest, re-pointed', () async {
      final contest = await source.contestNamed(_autumn);
      final repo = Repository(source.db);
      final participation =
          (await repo.contestParticipationRepository.listForContest(contest.id))
              .first;
      core.ImportProvenance stamp(
        String type,
        core.Id entity, {
        core.Id? contestId,
        String? dedupeKey,
      }) => core.ImportProvenance(
        id: core.Id.create(),
        ownerAccountId: source.localId,
        contestId: contestId,
        stampedEntityType: type,
        stampedEntityId: entity,
        sourceSystem: core.ImportProvenance.gliderScore,
        sourceKeys: switch (type) {
          core.ImportProvenance.contestEntityType => const {'comp_no': 22},
          core.ImportProvenance.participationEntityType => const {
            'comp_no': 22,
            'pilot_no': 98,
          },
          _ => const {'pilot_no': 98},
        },
        sourceValues: dedupeKey == null ? null : const {'lane_count': 6},
        fileFingerprint: 'sha256:abc',
        dedupeKey: dedupeKey,
        importOperationId: core.Id.create(),
        toolVersion: '1.0.0',
        importedAt: DateTime.utc(2026, 11, 3),
      );
      final stamps = [
        stamp(
          core.ImportProvenance.contestEntityType,
          contest.id,
          contestId: contest.id,
          dedupeKey: 'gliderscore:sha256:abc:22',
        ),
        stamp(
          core.ImportProvenance.participationEntityType,
          participation.id,
          contestId: contest.id,
        ),
        stamp(
          core.ImportProvenance.profileEntityType,
          participation.participantProfileId,
        ),
      ];
      for (final s in stamps) {
        await repo.importProvenanceRepository.save(s, metadata: metadata());
      }

      final file = await source.exportNamed(_autumn);
      expect(file.rows('import_provenance'), hasLength(2));
      await target.importer.import(
        file,
        mode: ImportMode.editable,
        target: target.target,
      );

      final copied = await Repository(target.db).importProvenanceRepository
          .listForContest(contest.id);
      expect(
        copied.map((c) => c.id),
        unorderedEquals([stamps[0].id, stamps[1].id]),
      );
      expect(copied.every((c) => c.ownerAccountId == target.localId), isTrue);
      expect(
        (await Repository(target.db).importProvenanceRepository.findByDedupeKey(
          target.localId,
          'gliderscore:sha256:abc:22',
        ))?.sourceValues,
        {'lane_count': 6},
      );
    });

    test('an imported GliderScore contest keeps its stamps', () async {
      final repo = Repository(source.db);
      final profiles = <int, core.Id>{};
      for (var n = 1; n <= 2; n++) {
        final saved = await repo.participantProfileRepository.save(
          core.ParticipantProfile(
            id: core.Id.create(),
            ownerAccountId: source.localId,
            firstName: 'Pilot',
            lastName: 'Number$n',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
          metadata: metadata(),
        );
        profiles[n] = saved.id;
      }
      core.CompetitionImportPlan plan() => core.CompetitionImportPlan(
        draft: core.ContestImportDraft(
          sourceCompNo: 22,
          sourceClass: 'F5J',
          status: core.ContestImportStatus.importable,
          name: 'Imported Open',
          startDate: DateTime.utc(2026, 5, 9),
          disciplineType: 'F5J',
          config: core.ContestConfig(core: const {}, discipline: const {}),
          sourceLaneCount: 6,
          participants: const [
            core.ParticipationDraft(
              sourcePilotNo: 1,
              role: core.ImportedRole.pilot,
              sourceRole: 'Plt',
            ),
            core.ParticipationDraft(
              sourcePilotNo: 2,
              role: core.ImportedRole.pilot,
              sourceRole: 'Plt',
            ),
          ],
        ),
        profileIds: profiles,
        owner: core.ImportOwner(localAccountId: source.localId),
        timezone: 'UTC',
        importOperationId: core.Id.parse(
          '019c0000-0000-7000-8000-0000000000f1',
        ),
        fileFingerprint: 'sha256:abc',
        toolVersion: '1.0.0',
      );
      final first = await repo.contestImportRepository.importCompetition(
        plan(),
        metadata: metadata(),
      ) as core.CompetitionImported;

      final file = await source.exportNamed('Imported Open');
      expect(file.rows('import_provenance'), hasLength(3));
      await target.importer.import(
        file,
        mode: ImportMode.editable,
        target: target.target,
      );

      final copied = Repository(target.db);
      final stamps = await copied.importProvenanceRepository.listForContest(
        first.contestId,
      );
      expect(stamps, hasLength(3));
      expect(stamps.every((s) => s.ownerAccountId == target.localId), isTrue);
      final contest = await copied.contestRepository.findById(first.contestId);
      expect(contest!.ownerAccountId, target.localId);
      expect(
        (await copied.importProvenanceRepository.findByDedupeKey(
          target.localId,
          'gliderscore:sha256:abc:22',
        ))?.sourceValues,
        {'lane_count': 6},
      );
    });

    test('a restored contest keeps its draw, scores and stamps', () async {
      final repo = Repository(source.db);
      final json = jsonDecode(
        File(
          '../soar_score_core/test/fixtures/gliderscore/'
          'scores_reference.json',
        ).readAsStringSync(),
      ) as Map<String, Object?>;
      final plan = const core.GliderScoreRestoreMapper()
          .map(
            core.GliderScoreImportResult(
              id: core.Id.create(),
              sourceDbFile: 'x.mdb',
              tables: [
                for (final t
                    in (json['tables']! as List).cast<Map<String, Object?>>())
                  core.GliderScoreTable(
                    name: t['name']! as String,
                    rows: (t['rows']! as List).cast<Map<String, Object?>>(),
                    rowCount: t['rowCount']! as int,
                    rowCapExceeded: false,
                  ),
              ],
            ),
          )
          .firstWhere((p) => p.sourceCompNo == 35);
      final profiles = <int, core.Id>{};
      for (final p in plan.contest.participants) {
        final saved = await repo.participantProfileRepository.save(
          core.ParticipantProfile(
            id: core.Id.create(),
            ownerAccountId: source.localId,
            firstName: 'Pilot',
            lastName: 'Number${p.sourcePilotNo}',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
          metadata: metadata(),
        );
        profiles[p.sourcePilotNo] = saved.id;
      }
      final restored = await repo.contestImportRepository.importRestore(
        core.RestoreImportPlan(
          plan: plan,
          profileIds: profiles,
          owner: core.ImportOwner(localAccountId: source.localId),
          timezone: 'UTC',
          importOperationId: core.Id.create(),
          fileFingerprint: 'sha256:abc',
          toolVersion: '1.0.0',
          completed: true,
        ),
        metadata: metadata(),
      ) as core.CompetitionRestored;

      final file = await source.exportNamed(plan.contest.name!);
      await target.importer.import(
        file,
        mode: ImportMode.editable,
        target: target.target,
      );

      final copied = Repository(target.db);
      final stamps = await copied.importProvenanceRepository.listForContest(
        restored.contestId,
      );
      for (final type in const [
        'Contest',
        'ContestScores',
        'MatrixRevision',
        'ContestParticipation',
      ]) {
        expect(
          stamps.where((s) => s.stampedEntityType == type),
          isNotEmpty,
          reason: type,
        );
      }
      expect(stamps.every((s) => s.ownerAccountId == target.localId), isTrue);
      final matrix = await core.MatrixService(copied)
          .current(restored.contestId);
      expect(matrix.rounds, isNotEmpty);
      expect(
        (await copied.scorePlaceholderRepository.listForContest(
          restored.contestId,
        )).where((p) => p.state == core.ScorePlaceholderState.official).length,
        plan.flights.length,
      );
      expect(
        (await copied.contestRepository.findById(restored.contestId))!
            .lifecycleState,
        core.LifecycleState.completed,
      );
    });

    test('keeps pending changes so they can be sent later', () async {
      final file = await source.exportNamed(_autumn);
      await target.importer.import(
        file,
        mode: ImportMode.editable,
        target: target.target,
      );
      final pending = await target.inst.syncStore.pendingMutations(
        core.ContestScopeKey(core.Id.parse(file.header.contestId)),
      );
      expect(
        pending,
        hasLength(
          file
              .rows('mutation_records')
              .where(
                (m) => m['contest_id'] != null && m['outcome'] == 'Pending',
              )
              .length,
        ),
      );
      expect(pending.every((m) => m.actorId == target.localId), isTrue);
      expect(pending.map((m) => m.clientMutationId).toSet(), {
        for (final m in file.rows('mutation_records'))
          if (m['contest_id'] != null && m['outcome'] == 'Pending')
            m['client_mutation_id'],
      });
    });

    Future<ExchangeFile> synced({String? owner}) async {
      final contest = await source.contestNamed(_autumn);
      final account = owner ?? core.Id.create().value;
      await source.db.customStatement(
        "UPDATE contests SET owner_account_id = '$account' WHERE id = '${contest.id.value}'",
      );
      await source.db.customStatement(
        "INSERT INTO local_sync_positions (scope_kind, scope_id, last_synced_sequence) "
        "VALUES ('Contest', '${contest.id.value}', 4)",
      );
      return source.exportNamed(_autumn);
    }

    test('is not offered for a synced contest of another account', () async {
      final file = await synced();
      for (final signedIn in [null, core.Id.create()]) {
        final importer = ImportTarget(
          localAccountId: target.localId,
          signedInAccountId: signedIn,
        );
        final preview = await target.importer.preview(file, target: importer);
        expect(preview.availableModes, [ImportMode.inspection]);
        expect(preview.unavailableModes[ImportMode.editable], isNotNull);
        await expectLater(
          target.importer.import(
            file,
            mode: ImportMode.editable,
            target: importer,
          ),
          throwsA(
            isA<ExchangeException>().having(
              (e) => e.code,
              'code',
              'mode_unavailable',
            ),
          ),
        );
      }
      expect(
        await countWhere(target.db, 'contests', 'id', file.header.contestId),
        0,
      );
    });

    test('is offered to the account that owns the contest', () async {
      final account = core.Id.create();
      final file = await synced(owner: account.value);
      final importer = ImportTarget(
        localAccountId: target.localId,
        signedInAccountId: account,
      );
      final result = await target.importer.import(
        file,
        mode: ImportMode.editable,
        target: importer,
      );
      expect(result.ownerId, account);
      expect((await target.contestNamed(_autumn)).ownerAccountId, account);
    });

    test('an unknown sync state counts as synced', () async {
      final contest = await source.contestNamed(_autumn);
      await source.db.customStatement(
        "UPDATE contests SET owner_account_id = '${core.Id.create().value}' "
        "WHERE id = '${contest.id.value}'",
      );
      final file = await source.exportNamed(_autumn);
      expect(file.header.sourceSyncState, SourceSyncState.unknown);
      final preview = await target.importer.preview(
        file,
        target: target.target,
      );
      expect(preview.availableModes, [ImportMode.inspection]);
    });
  });

  group('untrusted files', () {
    test('a file that is not an export is refused', () {
      for (final text in ['not json', '[]', '{"format":"other"}']) {
        expect(
          () => ExchangeFile.decode(utf8.encode(text)),
          throwsA(
            isA<ExchangeException>().having(
              (e) => e.code,
              'code',
              'not_a_contest_file',
            ),
          ),
        );
      }
    });

    test('a newer format is refused with advice to update', () async {
      final json = (await source.exportNamed(_autumn)).toJson();
      (json['header'] as Map)['format_version'] = exchangeFormatVersion + 1;
      expect(
        () => ExchangeFile.decode(utf8.encode(jsonEncode(json))),
        throwsA(
          isA<ExchangeException>().having(
            (e) => e.code,
            'code',
            'format_too_new',
          ),
        ),
      );
    });

    test('a different schema version is refused naming both', () async {
      final file = await source.exportNamed(_autumn);
      final json = file.toJson();
      (json['header'] as Map)['schema_version'] = 3;
      final changed = ExchangeFile.decode(utf8.encode(jsonEncode(json)));
      final preview = await target.importer.preview(
        changed,
        target: target.target,
      );
      final refusal = preview.refusals.single;
      expect(refusal.code, 'schema_mismatch');
      expect(
        refusal.message,
        allOf(contains('3'), contains('${target.db.schemaVersion}')),
      );
    });

    test('a version 1 contest export imports into version 2', () async {
      final file = await source.exportNamed(_autumn);
      final json = file.toJson();
      (json['header'] as Map)['schema_version'] = 1;
      final legacy = ExchangeFile.decode(utf8.encode(jsonEncode(json)));
      final result = await importInspection(legacy);
      expect(result.contestId.value, file.header.contestId);
    });

    test('an export from before slot pointers fills them on import', () async {
      final file = await source.exportNamed(_autumn);
      final current = {
        for (final row in file.rows('score_placeholders'))
          row['id']! as String: row['current_attempt_id'] as String?,
      };
      expect(current.values.whereType<String>(), isNotEmpty);
      final officials = {
        for (final row in file.rows('official_scores'))
          row['score_placeholder_id']! as String: row['score_attempt_id'],
      };
      for (final row in file.rows('score_placeholders')) {
        row.remove('current_attempt_id');
      }
      final json = file.toJson();
      (json['header'] as Map)['schema_version'] = 1;
      final legacy = ExchangeFile.decode(utf8.encode(jsonEncode(json)));

      final result = await importInspection(legacy);

      expect(result.contestId.value, file.header.contestId);
      final rows = await target.db
          .customSelect(
            'SELECT id, score_revision, current_attempt_id '
            'FROM score_placeholders WHERE contest_id = ?',
            variables: [Variable.withString(file.header.contestId)],
          )
          .get();
      expect(rows, hasLength(current.length));
      var scored = 0;
      for (final row in rows) {
        final id = row.read<String>('id');
        final pointer = row.read<String?>('current_attempt_id');
        if (officials.containsKey(id)) {
          scored++;
          expect(pointer, officials[id], reason: 'scored slot $id');
        } else if (row.read<int>('score_revision') == 0) {
          expect(pointer, isNull, reason: 'unscored slot $id');
        }
      }
      expect(scored, greaterThan(0));
    });

    test('a current export keeps the pointers it carries', () async {
      final file = await source.exportNamed(_autumn);
      final carried = {
        for (final row in file.rows('score_placeholders'))
          if (row['current_attempt_id'] != null)
            row['id']! as String: row['current_attempt_id']! as String,
      };
      expect(carried, isNotEmpty);

      await importInspection(file);

      for (final entry in carried.entries) {
        final row = await target.db
            .customSelect(
              'SELECT current_attempt_id FROM score_placeholders WHERE id = ?',
              variables: [Variable.withString(entry.key)],
            )
            .getSingle();
        expect(row.read<String?>('current_attempt_id'), entry.value);
      }
    });

    test('too much nesting is refused', () {
      var node = <String, Object?>{};
      final root = node;
      for (var i = 0; i < exchangeMaxDepth + 2; i++) {
        final next = <String, Object?>{};
        node['n'] = next;
        node = next;
      }
      expect(
        () => ExchangeFile.decode(
          utf8.encode(jsonEncode({'format': 'rcsoar', 'header': root})),
        ),
        throwsA(
          isA<ExchangeException>().having((e) => e.code, 'code', 'too_deep'),
        ),
      );
    });

    test('nesting is checked before the file is parsed', () {
      final text = '{"format":"rcsoar","header":${'[' * 200000}';
      expect(
        () => ExchangeFile.decode(utf8.encode(text)),
        throwsA(
          isA<ExchangeException>().having((e) => e.code, 'code', 'too_deep'),
        ),
      );
    });

    Future<List<String>> refusalsAfter(
      void Function(ExchangeFile) tamper,
    ) async {
      final file = await source.exportNamed(_autumn);
      tamper(file);
      final preview = await target.importer.preview(
        file,
        target: target.target,
      );
      expect(preview.availableModes, isEmpty);
      return [for (final r in preview.refusals) r.code];
    }

    test(
      'unknown tables, bad ids, missing columns and foreign rows are refused',
      () async {
        expect(
          await refusalsAfter(
            (f) => f.tables['accounts'] = [
              {'id': 'x'},
            ],
          ),
          contains('unknown_table'),
        );
        expect(
          await refusalsAfter(
            (f) => f.rows('rounds').first['id'] = 'not-an-id',
          ),
          contains('invalid_id'),
        );
        expect(
          await refusalsAfter((f) => f.rows('rounds').first.remove('ordinal')),
          contains('malformed_row'),
        );
        expect(
          await refusalsAfter((f) => f.rows('rounds').first['extra'] = 1),
          contains('malformed_row'),
        );
        expect(
          await refusalsAfter(
            (f) =>
                f.rows('rounds').first['contest_id'] = core.Id.create().value,
          ),
          contains('foreign_row'),
        );
        expect(
          await refusalsAfter(
            (f) => f.tables['contests']!.add({...f.rows('contests').single}),
          ),
          contains('malformed_contest'),
        );
      },
    );

    test(
      'a missing contest table is refused, not imported partially',
      () async {
        expect(
          await refusalsAfter((f) => f.tables.remove('official_scores')),
          contains('missing_table'),
        );
      },
    );

    test('director rows the contest does not use are refused', () async {
      expect(
        await refusalsAfter((f) {
          final profile = {...f.rows('participant_profiles').first};
          profile['id'] = core.Id.create().value;
          f.tables['participant_profiles']!.add(profile);
        }),
        contains('unreferenced_row'),
      );
    });

    test('a row id used by another contest is refused, and kept', () async {
      await importInspection(await source.exportNamed(_mountain));
      final taken = (await target.exportNamed(_mountain)).rows('rounds').first;
      final file = await source.exportNamed(_autumn);
      file.rows('rounds').first['id'] = taken['id'];

      final preview = await target.importer.preview(
        file,
        target: target.target,
      );
      expect(preview.availableModes, isEmpty);
      expect([
        for (final r in preview.refusals) r.code,
      ], contains('row_exists'));
      await expectLater(
        importInspection(file),
        throwsA(isA<ImportRefusedException>()),
      );
      expect(
        await countWhere(target.db, 'rounds', 'id', taken['id'] as String),
        1,
      );
      expect((await target.exportNamed(_mountain)).rows('rounds').first, taken);
    });

    test('duplicate ids inside one table are refused', () async {
      expect(
        await refusalsAfter(
          (f) => f.tables['rounds']!.add({...f.rows('rounds').first}),
        ),
        contains('duplicate_id'),
      );
    });

    test('a pending change of a director row never replaces another', () async {
      final file = await source.exportNamed(_autumn);
      final template = file.rows('mutation_records').first;
      final record = {
        ...template,
        'id': core.Id.create().value,
        'contest_id': null,
        'owner_account_id': source.localId.value,
        'entity_id': file.rows('participant_profiles').first['id'],
      };
      file.tables['mutation_records']!.add(record);
      await EntityStores.forDatabase(target.db)
          .of('MutationRecord')
          .upsertJson({...record, 'client_mutation_id': 'x'});

      final preview = await target.importer.preview(
        file,
        target: target.target,
      );
      expect(preview.availableModes, isEmpty);
      for (final mode in ImportMode.values) {
        expect([
          for (final r in preview.refusalsFor(mode)) r.code,
        ], contains('row_exists'));
      }
    });

    test('a file cannot bring an inspection owner marker', () async {
      final victim = core.Id.create();
      final file = await source.exportNamed(_autumn);
      file.tables['audit_events']!.add({
        ...InspectionOwnerMarkers.markerRow(
          owner: victim,
          identities: {victim.value},
          at: DateTime.utc(2026, 10, 22),
          contestId: core.Id.parse(file.header.contestId),
        ),
        'contest_id': file.header.contestId,
      });

      expect(
        await refusalsAfter(
          (f) => f.tables['audit_events'] = file.tables['audit_events']!,
        ),
        contains('reserved_row'),
      );
      expect(await InspectionOwnerMarkers(target.db).isMarked(victim), isFalse);
    });

    test('only a marker without a contest counts', () async {
      final victim = core.Id.create();
      await EntityStores.forDatabase(target.db).of('AuditEvent').upsertJson({
        ...InspectionOwnerMarkers.markerRow(
          owner: victim,
          identities: {victim.value},
          at: DateTime.utc(2026, 10, 22),
          contestId: core.Id.create(),
        ),
        'contest_id': null,
        'owner_account_id': core.Id.create().value,
      });
      final markers = InspectionOwnerMarkers(target.db);

      expect(await markers.isMarked(victim), isFalse);
      expect((await markers.load()).isEmpty, isTrue);
    });

    test('values are only ever bound, never run as SQL', () async {
      final file = await source.exportNamed(_autumn);
      file.rows('contests').single['name'] = "x'); DROP TABLE contests; --";
      await importInspection(file);
      expect(
        (await target.contestNamed("x'); DROP TABLE contests; --")).id.value,
        file.header.contestId,
      );
    });
  });

  group('transforms', () {
    final from = core.Id.create().value;
    final other = core.Id.create().value;
    final to = core.Id.create().value;

    test('rewrite touches account columns and account keys only', () {
      final tables = <String, List<Map<String, Object?>>>{
        'contests': [
          {'id': 'c', 'name': 'see $from', 'owner_account_id': from},
        ],
        'score_attempts': [
          {'id': 'a', 'actor_id': from, 'client_mutation_id': from},
          {'id': 'b', 'actor_id': other, 'client_mutation_id': 'm'},
        ],
        'mutation_records': [
          {
            'id': 'm',
            'client_mutation_id': from,
            'actor_id': from,
            'owner_account_id': null,
            'payload': {
              'data': {
                'entity': {
                  'owner_account_id': from,
                  'name': from,
                  'actor_id': other,
                },
              },
            },
          },
        ],
      };
      final rewritten = rewriteAccountReferences(tables, from: {from}, to: to);
      expect(rewritten['contests']!.single['owner_account_id'], to);
      expect(rewritten['contests']!.single['name'], 'see $from');
      expect(rewritten['score_attempts']![0]['actor_id'], to);
      expect(rewritten['score_attempts']![0]['client_mutation_id'], from);
      expect(rewritten['score_attempts']![1]['actor_id'], other);
      final mutation = rewritten['mutation_records']!.single;
      expect(mutation['client_mutation_id'], from);
      expect(mutation['actor_id'], to);
      expect(mutation['owner_account_id'], isNull);
      final entity =
          ((mutation['payload'] as Map)['data'] as Map)['entity'] as Map;
      expect(entity, {'owner_account_id': to, 'name': from, 'actor_id': other});
      // The input is not changed.
      expect(tables['contests']!.single['owner_account_id'], from);
    });

    test('an ownerless contest is given the importing owner', () {
      final rewritten = rewriteAccountReferences(
        {
          'contests': [
            {'id': 'c', 'owner_account_id': null},
          ],
          'audit_events': [
            {'id': 'e', 'owner_account_id': null, 'actor_id': null},
          ],
        },
        from: {from},
        to: to,
      );
      expect(rewritten['contests']!.single['owner_account_id'], to);
      expect(rewritten['audit_events']!.single['owner_account_id'], isNull);
    });
  });
}
