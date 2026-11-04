import 'package:soar_score_contest/services/pilot_import/pilot_import.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// A GliderScore snapshot with the given `Pilots` rows.
GliderScoreImportResult pilotsSnapshot(List<Map<String, Object?>> rows) =>
    GliderScoreImportResult(
      id: Id.create(),
      sourceDbFile: 'Contest.mdb',
      tables: [
        GliderScoreTable(
          name: 'Pilots',
          rows: rows,
          rowCount: rows.length,
          rowCapExceeded: false,
        ),
      ],
    );

ParticipantProfile profile({
  required String first,
  required String last,
  String? email,
  String? club,
  int revision = 0,
  Id? id,
}) => ParticipantProfile(
  id: id ?? Id.create(),
  ownerAccountId: Id.create(),
  firstName: first,
  lastName: last,
  email: email,
  club: club,
  createdAt: DateTime.utc(2026, 10),
  updatedAt: DateTime.utc(2026, 10),
  revision: revision,
);

/// An in-memory [PilotImportStore] that records what it was asked to save.
class FakePilotImportStore implements PilotImportStore {
  FakePilotImportStore(this.profiles);

  List<ParticipantProfile> profiles;
  final applied = <List<PilotImportSelection>>[];
  final appliedRevisions = <Map<Id, int>>[];
  Object? applyError;

  @override
  Future<List<ParticipantProfile>> existing() async => profiles;

  @override
  Future<PilotImportOutcome> apply(
    List<PilotImportSelection> selections, {
    required Map<Id, int> reviewedRevisions,
  }) async {
    if (applyError != null) throw applyError!;
    applied.add(selections);
    appliedRevisions.add(reviewedRevisions);
    var added = <ParticipantProfile>[], updated = <ParticipantProfile>[];
    var unchanged = 0, skipped = 0;
    for (final s in selections) {
      switch (s.choice) {
        case PilotImportChoice.skip:
          skipped++;
        case PilotImportChoice.add:
          added.add(
            profile(
              id: s.newProfileId,
              first: s.match.draft.firstName,
              last: s.match.draft.lastName,
            ),
          );
        case PilotImportChoice.update:
          if (s.match.isUnchanged) {
            unchanged++;
          } else {
            updated.add(
              profile(
                id: s.targetProfileId ?? s.match.candidateIds.single,
                first: 'x',
                last: 'y',
              ),
            );
          }
      }
    }
    return PilotImportOutcome(
      added: added,
      updated: updated,
      unchanged: unchanged,
      skipped: skipped,
    );
  }
}
