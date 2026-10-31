import 'package:soar_score_core/soar_score_core.dart';

import '../../matrix/matrix_page_data.dart';
import '../../scoring/score_entry_settings.dart';
import '../../scoring/time_entry.dart';
import '../draw_matrix/draw_matrix_data.dart';
import 'card_columns.dart';
import 'pilot_invitations.dart';

/// The scores already entered for one flight, as the cells print them.
class CardScore {
  const CardScore({
    required this.text,
    required this.ticks,
    required this.official,
  });

  /// Time, Landing, Height and Penalty as printed. A missing entry prints as a
  /// dash, so a scored cell is never empty.
  final Map<CardField, String> text;

  /// Over 75 m and Motor restart: yes prints a check mark, no a dash.
  final Map<CardField, bool> ticks;

  /// False for a value that is not official yet: it prints with an asterisk.
  final bool official;
}

/// One row of a pilot's card: a flight they are drawn in.
class CardRow {
  const CardRow({
    required this.round,
    required this.group,
    this.lane,
    this.score,
  });

  final int round;

  /// "A", "B", ...
  final String group;
  final int? lane;

  /// The score entered for the flight, or `null`.
  final CardScore? score;
}

/// What the cards are built from: each pilot's drawn flights with the scores
/// entered so far, and the invitations. Read once; the round range, pilots and
/// options are applied to it without another read.
class PilotCardsData {
  PilotCardsData({
    required this.rowsByPilot,
    required this.hasLanes,
    required this.motorRestart,
    required this.invitations,
  });

  /// Reads [page]'s current matrix with [scores]; [landings] turn a landing
  /// choice into its points.
  factory PilotCardsData.of({
    required MatrixPageData page,
    required ContestScores scores,
    required List<LandingResult> landings,
    required ScoreEntrySettings settings,
    required PilotInvitationSession invitations,
  }) {
    final ordinals = {
      for (final round in page.matrix.rounds)
        if (round.isCurrent) round.id: round.ordinal,
    };
    final slots = {
      for (final slot in scores.slots) slot.placeholder.assignmentId: slot,
    };
    final points = {
      for (final landing in landings) landing.entryKey: landing.pointValue,
    };
    final rows = <String, List<CardRow>>{};
    var lanes = false;
    for (final assignment in page.matrix.assignments) {
      final round = ordinals[assignment.scheduledRoundId];
      if (assignment.isSuperseded || round == null) {
        continue;
      }
      lanes = lanes || assignment.lane != null;
      rows
          .putIfAbsent(assignment.contestParticipationId.value, () => [])
          .add(
            CardRow(
              round: round,
              group: DrawMatrixData.groupLabel(assignment.group - 1),
              lane: assignment.lane,
              score: scoreOf(slots[assignment.id], points),
            ),
          );
    }
    for (final list in rows.values) {
      list.sort((a, b) => a.round.compareTo(b.round));
    }
    return PilotCardsData(
      rowsByPilot: rows,
      hasLanes: lanes,
      motorRestart: settings.restartsAllowed,
      invitations: invitations,
    );
  }

  /// A pilot's rows by participation id, in round order.
  final Map<String, List<CardRow>> rowsByPilot;
  final bool hasLanes;

  /// The contest allows a motor restart.
  final bool motorRestart;
  final PilotInvitationSession invitations;

  List<CardRow> rowsOf(Id participation) =>
      rowsByPilot[participation.value] ?? const [];

  static CardScore? scoreOf(ScoreSlot? slot, Map<String, int> points) {
    final official = slot?.officialScore;
    if (slot == null || official == null) {
      return null;
    }
    final c = official.components;
    String number(Object? value) => value is num ? '${value.toInt()}' : '–';
    final landing = c['landing'];
    final penalty = c['flight_penalty'];
    return CardScore(
      text: {
        CardField.time: c['time_flown'] is num
            ? TimeEntry.clock(c['time_flown']! as num)
            : '–',
        CardField.landing: landing is String && points[landing] != null
            ? '${points[landing]}'
            : '–',
        CardField.height: number(c['launch_height']),
        CardField.penalty: penalty is num && penalty > 0
            ? '${penalty.toInt()}'
            : '–',
      },
      ticks: {
        CardField.over75: c['out_of_bounds'] == true,
        CardField.restart: c['motor_restart'] == true,
      },
      official: slot.placeholder.state == ScorePlaceholderState.official,
    );
  }
}
