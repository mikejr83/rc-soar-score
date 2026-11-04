import 'dart:convert';
import 'dart:io';

import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

const _fixtures = '../soar_score_core/test/fixtures/gliderscore';

core.GliderScoreImportResult _snapshot(String file) {
  final json = jsonDecode(
    File('$_fixtures/$file').readAsStringSync(),
  ) as Map<String, Object?>;
  return core.GliderScoreImportResult(
    id: core.Id.create(),
    sourceDbFile: json['sourceDbFile']! as String,
    tables: [
      for (final t
          in (json['tables']! as List<Object?>).cast<Map<String, Object?>>())
        core.GliderScoreTable(
          name: t['name']! as String,
          rows: (t['rows']! as List<Object?>).cast<Map<String, Object?>>(),
          rowCount: t['rowCount']! as int,
          rowCapExceeded: t['rowCapExceeded']! as bool,
        ),
    ],
  );
}

core.RestorePlan _mapped(String file, int comp) =>
    const core.GliderScoreRestoreMapper()
        .map(_snapshot(file))
        .firstWhere((p) => p.sourceCompNo == comp);

void _tests(Backend backend) {
  late Installation inst;
  late ContestImportRepository importer;
  late Repository repository;
  final owner = core.Id.create();
  final signedIn = core.ImportOwner(signedInAccountId: owner);

  setUp(() async {
    inst = await Installation.open(backend);
    await SystemDataSeeder(inst.db).seed();
    importer = ContestImportRepository(inst.db);
    repository = Repository(inst.db);
  });
  tearDown(() => inst.close());

  Future<core.RestoreImportPlan> planFor(
    core.RestorePlan restore, {
    bool completed = true,
    bool confirmed = false,
    core.Id? contestId,
  }) async {
    final profiles = <int, core.Id>{};
    for (final p in restore.contest.participants) {
      final existing = await repository.participantProfileRepository
          .listForOwner(owner);
      final name = 'Pilot${p.sourcePilotNo}';
      final found = existing.where((e) => e.lastName == name).firstOrNull;
      if (found != null) {
        profiles[p.sourcePilotNo] = found.id;
        continue;
      }
      final saved = await repository.participantProfileRepository.save(
        core.ParticipantProfile(
          id: core.Id.create(),
          ownerAccountId: owner,
          firstName: 'Pilot',
          lastName: name,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        metadata: metadata(),
      );
      profiles[p.sourcePilotNo] = saved.id;
    }
    return core.RestoreImportPlan(
      plan: restore,
      profileIds: profiles,
      owner: signedIn,
      timezone: 'UTC',
      importOperationId: core.Id.create(),
      fileFingerprint: 'sha256:abc',
      toolVersion: '1.0.0',
      completed: completed,
      confirmedReplace: confirmed,
      contestId: contestId,
    );
  }

  Future<core.RestoreImportResult> restore(
    core.RestorePlan plan, {
    bool completed = true,
    bool confirmed = false,
  }) async {
    final result = await importer.importRestore(
      await planFor(plan, completed: completed, confirmed: confirmed),
      metadata: metadata(),
    );
    if (result is core.CompetitionRestoreFailed &&
        result.code == core.RestoreFailure.failed) {
      fail('restore failed: ${result.detail}');
    }
    return result;
  }

  Future<int> count(String table) async =>
      (await inst.db
              .customSelect('SELECT COUNT(*) AS c FROM $table')
              .getSingle())
          .read<int>('c');

  group('importRestore', () {
    test('restores a completed competition', () async {
      final plan = _mapped('scores_reference.json', 35);
      final result = await restore(plan);
      final done = result as core.CompetitionRestored;
      expect(done.updated, isFalse);
      expect(done.flightCount, plan.flights.length);
      expect(done.finalState, core.RestoreFinalState.completed);
      // The reports read stored results, so the restore stores them.
      expect(await count('participation_standings'), greaterThan(0));
      expect(await count('flight_results'), plan.flights.length);
      expect(
        (await core.ResultsService(repository).read(done.contestId)).standings,
        isNotEmpty,
      );

      final contest = (await repository.contestRepository.findById(
        done.contestId,
      ))!;
      expect(contest.lifecycleState, core.LifecycleState.completed);
      expect(contest.adminLock, core.AdminLock.locked);
      expect(await count('official_scores'), plan.flights.length);
      expect(await count('score_attempts'), plan.flights.length);

      final rounds = await repository.roundRepository.listForContest(
        done.contestId,
      );
      expect(
        rounds.where((r) => r.status == core.RoundStatus.cancelled).length,
        plan.trailingUnflownRounds.length,
      );
      final ordinals = rounds
          .where((r) => r.status == core.RoundStatus.locked)
          .length;
      expect(ordinals, rounds.length - plan.trailingUnflownRounds.length);

      final placeholders = await repository.scorePlaceholderRepository
          .listForContest(done.contestId);
      expect(
        placeholders
            .where((p) => p.state == core.ScorePlaceholderState.official)
            .length,
        plan.flights.length,
      );
    });

    test('a running restore stays open for scoring', () async {
      final plan = _mapped('scores_reference.json', 35);
      final done =
          await restore(plan, completed: false) as core.CompetitionRestored;
      expect(done.finalState, core.RestoreFinalState.running);
      final contest = (await repository.contestRepository.findById(
        done.contestId,
      ))!;
      expect(contest.lifecycleState, core.LifecycleState.running);
      expect(contest.adminLock, core.AdminLock.unlocked);
      final rounds = await repository.roundRepository.listForContest(
        done.contestId,
      );
      expect(rounds.every((r) => r.status == core.RoundStatus.open), isTrue);
    });

    test('stores re-flights and retirements', () async {
      final plan = _mapped('draws_reference.json', 21);
      final done = await restore(plan) as core.CompetitionRestored;
      // The re-flown flights count in place of the ones they replaced.
      expect(
        (await core.ResultsService(repository).read(done.contestId)).standings,
        isNotEmpty,
      );
      final reflights = await repository.reFlightRepository.listForContest(
        done.contestId,
      );
      expect(reflights, hasLength(plan.reflights.length));
      expect(
        reflights.every((r) => r.status == core.ReFlightStatus.finalized),
        isTrue,
      );
      final participations = await repository.contestParticipationRepository
          .listForContest(done.contestId);
      expect(
        participations.where((p) => p.isRetired).length,
        plan.retirements.length,
      );
    });

    test('repeating an import writes nothing', () async {
      final plan = _mapped('scores_reference.json', 35);
      final first = await restore(plan) as core.CompetitionRestored;
      final mutations = await count('mutation_records');
      final second = await restore(plan);
      expect(second, isA<core.CompetitionUnchanged>());
      expect((second as core.CompetitionUnchanged).contestId, first.contestId);
      expect(await count('mutation_records'), mutations);
    });

    test('a changed file updates the contest in place', () async {
      final first = await restore(
        _mapped('reimport_v1.json', 19),
      ) as core.CompetitionRestored;
      final second = await restore(
        _mapped('reimport_v2.json', 19),
      ) as core.CompetitionRestored;
      expect(second.updated, isTrue);
      expect(second.contestId, first.contestId);
      expect(await count('contests'), 1);
      expect(
        await count('official_scores'),
        _mapped('reimport_v2.json', 19).flights.length,
      );
    });

    test('scores entered in Soar Score need confirming', () async {
      final v1 = _mapped('reimport_v1.json', 19);
      final first = await restore(v1, completed: false);
      final contestId = (first as core.CompetitionRestored).contestId;
      final scores = await repository.scorePlaceholderRepository.listForContest(
        contestId,
      );
      final open = scores.firstWhere(
        (p) => p.state == core.ScorePlaceholderState.notEntered,
        orElse: () => throw StateError('no open slot'),
      );
      await core.ScoresService(repository).enterOfficialScore(
        contestId,
        open.assignmentId,
        clientMutationId: 'later',
        baseScoreRevision: 0,
        components: const {'time_flown': 300, 'launch_height': 50},
        actorId: owner,
        metadata: metadata(),
      );
      final v2 = _mapped('reimport_v2.json', 19);
      final refused = await restore(v2, completed: false);
      expect(
        (refused as core.CompetitionRefused).code,
        core.RestoreRefusal.needsConfirmation,
      );
      final again = await restore(v2, completed: false, confirmed: true);
      expect(again, isA<core.CompetitionRestored>());
    });

    test('refuses a contest whose results are published', () async {
      // The publication table belongs to the server profile.
      await inst.close();
      inst = await Installation.open(backend, profile: DatabaseProfile.server);
      await SystemDataSeeder(inst.db).seed();
      importer = ContestImportRepository(inst.db);
      repository = Repository(inst.db);
      final plan = _mapped('reimport_v1.json', 19);
      final first =
          await restore(plan, completed: false) as core.CompetitionRestored;
      await inst.db.customStatement(
        'INSERT INTO publication_identities '
        '(id, contest_id, claim_status, visibility, published_at, revision) '
        "VALUES ('${core.Id.create().value}', '${first.contestId.value}', "
        "'Unclaimed', 'Public', '2026-05-01T00:00:00Z', 0)",
      );
      final result = await restore(_mapped('reimport_v2.json', 19));
      expect(
        (result as core.CompetitionRefused).code,
        core.RestoreRefusal.resultsPublished,
      );
    });

    test('refuses a contest that reached the server', () async {
      final first = await restore(
        _mapped('reimport_v1.json', 19),
        completed: false,
      ) as core.CompetitionRestored;
      await inst.db.customStatement(
        "UPDATE mutation_records SET outcome = 'Accepted' "
        "WHERE contest_id = '${first.contestId.value}' "
        'AND id IN (SELECT id FROM mutation_records WHERE contest_id = '
        "'${first.contestId.value}' LIMIT 1)",
      );
      final result = await restore(_mapped('reimport_v2.json', 19));
      expect(
        (result as core.CompetitionRefused).code,
        core.RestoreRefusal.contestSynced,
      );
    });

    test('a difference from GliderScore rolls everything back', () async {
      final good = _mapped('scores_reference.json', 35);
      final flights = [...good.flights];
      final f = flights.first;
      flights[0] = core.RestoredFlight(
        taskNo: f.taskNo,
        roundNo: f.roundNo,
        sourceGroupNo: f.sourceGroupNo,
        groupNo: f.groupNo,
        reflightNo: f.reflightNo,
        sourcePilotNo: f.sourcePilotNo,
        kind: f.kind,
        components: f.components,
        rawComponents: f.rawComponents,
        sourceRawScore: (f.sourceRawScore ?? 0) + 1,
      );
      final bad = core.RestorePlan(
        sourceCompNo: good.sourceCompNo,
        identity: good.identity,
        status: good.status,
        contest: good.contest,
        draw: good.draw,
        flights: flights,
        reflights: good.reflights,
        retirements: good.retirements,
        landing: good.landing,
        trailingUnflownRounds: good.trailingUnflownRounds,
        contentHash: 'other',
      );
      final result = await restore(bad);
      final failed = result as core.CompetitionRestoreFailed;
      expect(failed.code, core.RestoreFailure.comparisonFailed);
      expect(failed.mismatchCount, 1);
      expect(failed.mismatches.single.sourcePilotNo, f.sourcePilotNo);
      expect(await count('contests'), 0);
      expect(await count('official_scores'), 0);
      expect(await count('import_provenance'), 0);
    });

    test('finds an earlier restore without a CompID by number', () async {
      final plan = _mapped('reimport_no_compid.json', 19);
      await restore(plan, completed: false);
      final same = await importer.restoreTarget(signedIn, plan.identity);
      expect(same.kind, core.RestoreTargetKind.same);
      final other = await importer.restoreTarget(
        signedIn,
        core.RestoreIdentity(
          compNo: plan.identity.compNo,
          name: 'Another name',
          date: plan.identity.date,
        ),
      );
      expect(other.kind, core.RestoreTargetKind.numberMatch);
    });
  });
}
