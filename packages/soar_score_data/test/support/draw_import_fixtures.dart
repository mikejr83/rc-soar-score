import 'package:soar_score_core/soar_score_core.dart' as core;

/// One `Scores` row.
Map<String, Object?> scoreRow(
  int comp,
  int round,
  int group,
  int pilot,
  int seq, {
  bool scored = false,
}) => {
  'CompNo': comp,
  'TaskNo': 1,
  'RoundNo': round,
  'GroupNo': group,
  'ReFlightNo': 0,
  'PilotNo': pilot,
  'SeqNo': seq,
  'OriginalRoundNo': round,
  'Updated': scored ? 'True' : 'False',
};

/// Pilots 1..6 drawn into [groupsOf] (the group count of each round, 1
/// based), split evenly in pilot order.
List<Map<String, Object?>> drawRows(int comp, List<int> groupsOf) => [
  for (var r = 1; r <= groupsOf.length; r++)
    for (var p = 1; p <= 6; p++)
      scoreRow(
        comp,
        r,
        ((p - 1) * groupsOf[r - 1] ~/ 6) + 1,
        p,
        ((p - 1) % (6 ~/ groupsOf[r - 1])) + 1,
      ),
];

/// A competition file holding [rows], mapped with the real mapper for a
/// contest whose pilots are 1..6.
core.DrawImportDraft drawDraft(
  List<Map<String, Object?>> rows, {
  int compNo = 22,
  int lanes = 0,
  String fingerprint = 'sha256:abc',
  Set<int> pilots = const {1, 2, 3, 4, 5, 6},
}) {
  core.GliderScoreTable table(String name, List<Map<String, Object?>> rows) =>
      core.GliderScoreTable(
        name: name,
        rows: rows,
        rowCount: rows.length,
        rowCapExceeded: false,
      );
  final result = core.GliderScoreImportResult(
    id: core.Id.create(),
    sourceDbFile: 'test.mdb',
    tables: [
      table('Comps', [
        {'CompNo': compNo, 'GSCompClass': 'F5J'},
      ]),
      table('Dur', [
        {'CompNo': compNo, 'durNbrOfLanes': lanes, 'durGroupsPerRound': 2},
      ]),
      table('Scores', rows),
    ],
  );
  return const core.GliderScoreDrawMapper().mapCompetition(
    result,
    core.DrawImportTarget(
      sourceCompNo: compNo,
      fileFingerprint: fingerprint,
      stampedFingerprint: fingerprint,
      participantPilotNos: pilots,
    ),
  );
}
