import 'package:soar_score_contest/services/competition_import/competition_import.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'pilot_import_fakes.dart';

/// A GliderScore snapshot with two importable F5J competitions that share a
/// pilot, one F3J (skipped) and one F5J nobody flies in (blocked).
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
      for (final no in [1, 2, 4]) {'CompNo': no, 'durTargetTime': 600},
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

/// [competitionsSnapshot] with the drawn flights of "Spring Open" (competition
/// 1): two rounds, one group of two pilots each.
GliderScoreImportResult competitionsSnapshotWithDraw() {
  final base = competitionsSnapshot();
  final rows = [
    for (var round = 1; round <= 2; round++)
      for (final pilot in [1, 2])
        {
          'CompNo': 1,
          'TaskNo': 1,
          'RoundNo': round,
          'GroupNo': 1,
          'ReFlightNo': 0,
          'PilotNo': pilot,
          'SeqNo': pilot,
          'OriginalRoundNo': round,
          'Updated': 'False',
        },
  ];
  return GliderScoreImportResult(
    id: base.id,
    sourceDbFile: base.sourceDbFile,
    tables: [
      ...base.tables,
      GliderScoreTable(
        name: 'Scores',
        rows: rows,
        rowCount: rows.length,
        rowCapExceeded: false,
      ),
    ],
  );
}

/// The phase B contest of competition [compNo], as the store reports it.
DrawImportTarget stampedTarget(
  int compNo, {
  String fingerprint = 'sha256:fake',
  bool hasMatrix = false,
  Id? contestId,
}) => DrawImportTarget(
  sourceCompNo: compNo,
  fileFingerprint: 'sha256:fake',
  contestId: contestId ?? Id.create(),
  stampedFingerprint: fingerprint,
  hasMatrix: hasMatrix,
  participantPilotNos: const {1, 2},
);

/// A [CompetitionImportStore] that records what it was asked to write.
class FakeCompetitionImportStore extends FakePilotImportStore
    implements CompetitionImportStore {
  FakeCompetitionImportStore(super.profiles);

  final stamped = <List<ProfileStampEntry>>[];
  final imported = <(int compNo, Map<int, Id> profiles)>[];

  /// What [importCompetition] answers for a competition, when not the usual.
  final answers = <int, CompetitionImportResult>{};

  /// Competitions whose import throws instead of answering.
  final throwsFor = <int>{};

  /// The contest each competition already has, when it has one.
  final drawTargets = <int, DrawImportTarget>{};

  /// What [importDraw] answers for a competition, when not the usual.
  final drawAnswers = <int, DrawImportResult>{};

  /// The draws that were asked for, by competition number.
  final drawn = <(int compNo, Id contestId)>[];

  @override
  Future<DrawImportTarget> drawTarget({
    required int compNo,
    required String fingerprint,
  }) async =>
      drawTargets[compNo] ??
      DrawImportTarget(
        sourceCompNo: compNo,
        fileFingerprint: fingerprint,
        stamped: false,
      );

  @override
  Future<DrawImportResult> importDraw({
    required DrawImportDraft draft,
    required Id contestId,
    required Id operationId,
    required String fingerprint,
  }) async {
    final no = draft.sourceCompNo;
    drawn.add((no, contestId));
    return drawAnswers[no] ??
        DrawImported(
          no,
          contestId: contestId,
          revisionCount: draft.revisions.length,
          roundCount: draft.roundCount,
          assignmentCount: draft.assignmentCount,
        );
  }

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
  Future<CompetitionImportResult> importCompetition({
    required ContestImportDraft draft,
    required Map<int, Id> profileIds,
    required Id operationId,
    required String fingerprint,
  }) async {
    final no = draft.sourceCompNo;
    if (throwsFor.contains(no)) throw StateError('disk full');
    imported.add((no, profileIds));
    return answers[no] ??
        CompetitionImported(
          no,
          contestId: Id.create(),
          participationCount: draft.participants.length,
          skippedParticipants: [
            for (final p in draft.participants)
              if (!profileIds.containsKey(p.sourcePilotNo)) p.sourcePilotNo,
          ],
        );
  }
}
