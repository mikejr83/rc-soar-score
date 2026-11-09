import 'package:soar_score_contest/services/competition_import/competition_import.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'pilot_import_fakes.dart';

/// A GliderScore snapshot with two importable F5J competitions that share a
/// pilot (each with two rounds of scores), one F3J (skipped) and one F5J
/// nobody flies in (blocked).
GliderScoreImportResult competitionsSnapshot() {
  Map<String, Object?> comp(int no, String name, String cls) => {
    'CompNo': no,
    'CompName': name,
    'GSCompClass': cls,
    'CompDate': '06/14/26 00:00:00',
  };
  final tables = <String, List<Map<String, Object?>>>{
    'Comps': [
      comp(1, 'Spring Open', 'F5J'),
      comp(2, 'Autumn Open', 'F5J'),
      comp(3, 'Old F3J', 'F3J'),
      comp(4, 'Empty Cup', 'F5J'),
    ],
    'CompPilots': [
      {'CompNo': 1, 'PilotNo': 1},
      {'CompNo': 1, 'PilotNo': 2},
      {'CompNo': 2, 'PilotNo': 1},
      {'CompNo': 3, 'PilotNo': 3},
    ],
    'Pilots': [
      {'PilotNo': 1, 'FirstName': 'Ada', 'LastName': 'Lovelace'},
      {'PilotNo': 2, 'FirstName': 'Bo', 'LastName': 'Nilsson'},
      {'PilotNo': 3, 'FirstName': 'Cy', 'LastName': 'Young'},
    ],
    'Dur': [
      for (final no in [1, 2, 4])
        {'CompNo': no, 'durTargetTime': 600, 'durGroupsPerRound': 1},
    ],
    'Scores': [
      for (final no in [1, 2])
        for (var round = 1; round <= 2; round++)
          for (final pilot in no == 1 ? [1, 2] : [1])
            {
              'CompNo': no,
              'TaskNo': 1,
              'RoundNo': round,
              'GroupNo': 1,
              'ReFlightNo': 0,
              'PilotNo': pilot,
              'SeqNo': pilot,
              'OriginalRoundNo': round,
              'Updated': 'True',
              'Time1Mins': 900,
              'FlightScoreDeduction': 100,
              'Landing': 50,
              'RawScore': 590,
            },
    ],
  };
  return GliderScoreImportResult(
    id: Id.create(),
    sourceDbFile: 'Contest.mdb',
    tables: [
      for (final e in tables.entries)
        GliderScoreTable(
          name: e.key,
          rows: e.value,
          rowCount: e.value.length,
          rowCapExceeded: false,
        ),
    ],
  );
}

/// What a competition would meet when it was imported before: the contest an
/// earlier import made.
RestoreTarget earlierImport({
  RestoreTargetKind kind = RestoreTargetKind.same,
  Id? contestId,
  String name = 'Spring Open',
  ContestChanges changes = const ContestChanges(),
  bool published = false,
  bool synced = false,
  String? storedHash,
  bool? storedCompleted,
}) => RestoreTarget(
  kind: kind,
  contestId: contestId ?? Id.create(),
  contestName: name,
  sourceName: name,
  sourceDate: '2026-06-14',
  importedAt: DateTime.utc(2026, 6, 20),
  storedHash: storedHash,
  storedCompleted: storedCompleted,
  published: published,
  synced: synced,
  changes: changes,
);

/// A [CompetitionImportStore] that records what it was asked to write.
class FakeCompetitionImportStore extends FakePilotImportStore
    implements CompetitionImportStore {
  FakeCompetitionImportStore(super.profiles);

  final stamped = <List<ProfileStampEntry>>[];

  /// Each restore asked for, in order.
  final restored = <RestoreCall>[];

  /// What [importRestore] answers for a competition, when not the usual.
  final answers = <int, RestoreImportResult>{};

  /// Competitions whose restore throws instead of answering.
  final throwsFor = <int>{};

  /// What an earlier import left, by competition number.
  final targets = <int, RestoreTarget>{};

  /// The note each contest shows, when it has one.
  final notes = <Id, ImportedContestNote>{};

  @override
  Future<ImportedContestNote?> noteFor(Id contestId) async => notes[contestId];

  @override
  Future<String> fingerprint(String path) async => 'sha256:fake';

  @override
  Future<void> stampProfiles({
    required Id operationId,
    required String fingerprint,
    required List<ProfileStampEntry> entries,
  }) async => stamped.add(entries);

  @override
  Future<RestoreTarget> restoreTarget(RestoreIdentity identity) async =>
      targets[identity.compNo] ?? const RestoreTarget.none();

  @override
  Future<RestoreImportResult> importRestore({
    required RestorePlan plan,
    required Map<int, Id> profileIds,
    required Id operationId,
    required String fingerprint,
    required bool completed,
    required bool confirmedReplace,
    Id? updateContestId,
  }) async {
    final no = plan.sourceCompNo;
    if (throwsFor.contains(no)) throw StateError('disk full');
    restored.add(
      RestoreCall(
        no,
        profileIds,
        completed: completed,
        confirmedReplace: confirmedReplace,
        updateContestId: updateContestId,
      ),
    );
    return answers[no] ??
        CompetitionRestored(
          no,
          contestId: targets[no]?.contestId ?? Id.create(),
          updated: targets[no] != null,
          participationCount: plan.contest.participants.length,
          flightCount: plan.flights.length,
          finalState: plan.finalState(completed: completed),
          skippedParticipants: [
            for (final p in plan.contest.participants)
              if (!profileIds.containsKey(p.sourcePilotNo)) p.sourcePilotNo,
          ],
        );
  }
}

/// One restore the fake store was asked for.
class RestoreCall {
  const RestoreCall(
    this.compNo,
    this.profiles, {
    required this.completed,
    required this.confirmedReplace,
    this.updateContestId,
  });

  final int compNo;
  final Map<int, Id> profiles;
  final bool completed;
  final bool confirmedReplace;
  final Id? updateContestId;
}
