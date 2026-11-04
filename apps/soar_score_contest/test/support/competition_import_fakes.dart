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
