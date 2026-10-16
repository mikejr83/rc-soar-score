import 'scoring_page_data.dart';
import 'scoring_row.dart';

/// How many flights one round counts before and after a pilot retires or is
/// reinstated.
class RoundCountChange {
  const RoundCountChange({
    required this.ordinal,
    required this.before,
    required this.after,
  });

  final int ordinal;
  final int before;
  final int after;
}

/// What retiring a pilot from a round on (or taking it back) does to the
/// round counts, worked out from the loaded scores so the confirmation can
/// name it. The server decides the same way: a retired pilot's unscored
/// flights are not missing, and a score already entered still counts.
class RetireImpact {
  const RetireImpact({
    required this.pilot,
    required this.fromRound,
    required this.changes,
    required this.keptScores,
    required this.reinstating,
  });

  /// The impact of retiring the pilot of [row] from [fromRound] on.
  factory RetireImpact.retire(
    ScoringPageData data,
    ScoringRow row,
    int fromRound,
  ) => RetireImpact._of(data, row, fromRound, reinstating: false);

  /// The impact of taking back the retirement of the pilot of [row], which
  /// holds from its own retirement round on.
  factory RetireImpact.reinstate(ScoringPageData data, ScoringRow row) =>
      RetireImpact._of(
        data,
        row,
        row.pilot.retiredAtRound ?? 1,
        reinstating: true,
      );

  factory RetireImpact._of(
    ScoringPageData data,
    ScoringRow row,
    int fromRound, {
    required bool reinstating,
  }) {
    final changes = <RoundCountChange>[];
    var kept = 0;
    for (final round in data.rounds) {
      if (round.ordinal < fromRound) continue;
      final rows = [
        for (final group in data.groupNumbers(round))
          ...data.rowsOf(round, group),
      ];
      final before = rows.where((r) => !r.isMissed).length;
      final own = rows
          .where((r) => r.pilot.participationId == row.pilot.participationId)
          .toList();
      var after = before;
      for (final flight in own) {
        if (flight.isScored) {
          kept++;
        } else if (reinstating) {
          if (flight.isMissed) after++;
        } else if (!flight.isMissed) {
          after--;
        }
      }
      if (after != before) {
        changes.add(
          RoundCountChange(
            ordinal: round.ordinal,
            before: before,
            after: after,
          ),
        );
      }
    }
    return RetireImpact(
      pilot: row.pilot.name,
      fromRound: fromRound,
      changes: changes,
      keptScores: kept,
      reinstating: reinstating,
    );
  }

  final String pilot;
  final int fromRound;
  final List<RoundCountChange> changes;

  /// Scores already entered from [fromRound] on; they stay and still count.
  final int keptScores;
  final bool reinstating;

  /// "Round 3 counts 5 flights instead of 6."
  List<String> get changeLines => [
    for (final change in changes)
      'Round ${change.ordinal} counts ${_flights(change.after)} instead of '
          '${change.before}.',
  ];

  static String _flights(int n) => '$n ${n == 1 ? 'flight' : 'flights'}';
}
