import 'import_provenance.dart';

/// What the director should know about a contest that came from GliderScore,
/// worked out from its import stamps and never stored.
///
/// The import is a point-in-time restore: it carries no scores and no history
/// of its own (ADR 0006), so the note says what was left behind.
class ImportedContestNote {
  const ImportedContestNote({
    required this.importedAt,
    required this.drawImported,
    required this.lanesKept,
  });

  /// When the contest itself was imported.
  final DateTime importedAt;

  /// The contest holds a draw that came from GliderScore.
  final bool drawImported;

  /// The draw has lanes. `false` when GliderScore used none, so the order of
  /// each group is kept in the import record only.
  final bool lanesKept;

  /// The note for a contest with these [stamps], or `null` when the contest
  /// was not imported.
  static ImportedContestNote? fromStamps(Iterable<ImportProvenance> stamps) {
    ImportProvenance? contest;
    final revisions = <ImportProvenance>[];
    for (final s in stamps) {
      if (s.stampedEntityType == ImportProvenance.contestEntityType) {
        contest = s;
      } else if (s.stampedEntityType ==
          ImportProvenance.matrixRevisionEntityType) {
        revisions.add(s);
      }
    }
    if (contest == null) return null;
    return ImportedContestNote(
      importedAt: contest.importedAt,
      drawImported: revisions.isNotEmpty,
      lanesKept: revisions.every(
        (r) => r.sourceValues?.containsKey('positions') != true,
      ),
    );
  }
}
