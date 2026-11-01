import '../../scoring/scoring_page_data.dart';
import '../../scoring/time_entry.dart';
import '../draw_matrix/draw_matrix_data.dart';
import '../pilot_cards/pilot_cards_data.dart';
import '../report_pilot.dart';
import '../reports_facts.dart';

/// One pilot's row in a group of the Scoring Sheet.
class ScoringSheetPilot {
  const ScoringSheetPilot({required this.pilot, this.lane, this.score});

  final ReportPilot pilot;
  final int? lane;

  /// The score entered for the flight, or `null`.
  final CardScore? score;

  String get name => pilot.listName;

  /// The same flight with no score on it, for a sheet that is not pre-filled.
  ScoringSheetPilot withoutScore() =>
      ScoringSheetPilot(pilot: pilot, lane: lane);

  /// The pilot no longer flies from [round] on.
  bool retiredBy(int round) {
    final at = pilot.retiredAtRound;
    return at != null && round >= at;
  }
}

/// One group of a round, with its letter ("A").
class ScoringSheetGroup {
  const ScoringSheetGroup({required this.label, required this.pilots});

  final String label;
  final List<ScoringSheetPilot> pilots;
}

/// One drawn round with its groups in order.
class ScoringSheetRound {
  const ScoringSheetRound({required this.ordinal, required this.groups});

  final int ordinal;
  final List<ScoringSheetGroup> groups;
}

/// What the Scoring Sheet is built from: the live rounds of the current matrix
/// with the pilots in each group and the scores entered so far. Read once; the
/// round range, retired pilots, Pre-fill and the columns are applied to it
/// without another read.
class ScoringSheetData {
  const ScoringSheetData({
    required this.rounds,
    required this.hasLanes,
    required this.motorRestart,
    required this.workingTime,
    required this.discipline,
  });

  /// Arranges [page]'s current matrix for the pilots in [facts]. Superseded
  /// and cancelled rounds and superseded assignments are left out. Within a
  /// group, pilots run by lane when the draw gave lanes and by name otherwise.
  factory ScoringSheetData.of({
    required ReportsFacts facts,
    required ScoringPageData page,
  }) {
    final matrix = page.base.matrix;
    final ordinals = {
      for (final round in matrix.rounds)
        if (round.isCurrent) round.id: round.ordinal,
    };
    final pilots = {for (final p in facts.pilots) p.participationId.value: p};
    final slots = {
      for (final slot in page.scores.slots) slot.placeholder.assignmentId: slot,
    };
    final points = {
      for (final landing in page.landings) landing.entryKey: landing.pointValue,
    };
    final groups = <int, Map<int, List<ScoringSheetPilot>>>{};
    var lanes = false;
    for (final assignment in matrix.assignments) {
      final round = ordinals[assignment.scheduledRoundId];
      final pilot = pilots[assignment.contestParticipationId.value];
      if (assignment.isSuperseded || round == null || pilot == null) {
        continue;
      }
      lanes = lanes || assignment.lane != null;
      groups
          .putIfAbsent(round, () => {})
          .putIfAbsent(assignment.group, () => [])
          .add(
            ScoringSheetPilot(
              pilot: pilot,
              lane: assignment.lane,
              score: PilotCardsData.scoreOf(slots[assignment.id], points),
            ),
          );
    }
    int byName(ScoringSheetPilot a, ScoringSheetPilot b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());
    int byLane(ScoringSheetPilot a, ScoringSheetPilot b) {
      final lane = (a.lane ?? 1 << 30).compareTo(b.lane ?? 1 << 30);
      return lane != 0 ? lane : byName(a, b);
    }

    final rounds = [
      for (final round in groups.keys.toList()..sort())
        ScoringSheetRound(
          ordinal: round,
          groups: [
            for (final group in groups[round]!.keys.toList()..sort())
              ScoringSheetGroup(
                label: DrawMatrixData.groupLabel(group - 1),
                pilots: [...groups[round]![group]!]
                  ..sort(lanes ? byLane : byName),
              ),
          ],
        ),
    ];
    return ScoringSheetData(
      rounds: rounds,
      hasLanes: lanes,
      motorRestart: page.settings.restartsAllowed,
      workingTime: TimeEntry.clock(page.settings.workingTimeSeconds),
      discipline: facts.disciplineLabel,
    );
  }

  final List<ScoringSheetRound> rounds;

  /// Whether the draw gave lanes; without them there is no Lane column.
  final bool hasLanes;

  /// The contest allows a motor restart.
  final bool motorRestart;

  /// "10:00": set once for the contest.
  final String workingTime;

  /// The discipline as the wizard names it (`F5J`); `null` when unknown.
  final String? discipline;
}
