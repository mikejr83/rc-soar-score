import 'package:soar_score_core/soar_score_core.dart';

import '../matrix/matrix_pilot.dart';
import '../matrix/team_marker.dart';

/// How far one pilot's flight in a group has come.
enum RowStatus {
  /// No score yet.
  notEntered,

  /// A participant submission is waiting; no official score.
  submitted,

  /// An official score is saved.
  official,

  /// The score, group, round or contest is locked.
  locked,
}

/// One pilot's slot in a group: who flies, and what is saved for them.
class ScoringRow {
  const ScoringRow({
    required this.assignment,
    required this.pilot,
    required this.slot,
    this.team,
    this.result,
    this.locked = false,
  });

  final MatrixAssignment assignment;
  final MatrixPilot pilot;

  /// The placeholder and official score, or null before the slot exists.
  final ScoreSlot? slot;
  final TeamMarker? team;

  /// The calculated flight, once the round's results were computed.
  final FlightResult? result;

  /// True when a lock above the score applies (group, round).
  final bool locked;

  Id get id => assignment.id;
  int? get lane => assignment.lane;

  /// The saved components, empty when nothing is saved.
  Map<String, Object?> get savedComponents =>
      slot?.officialScore?.components ?? const {};

  /// The score revision a save is based on; 0 when nothing is entered.
  int get baseRevision => slot?.placeholder.scoreRevision ?? 0;

  bool get hasSubmission =>
      slot?.placeholder.state == ScorePlaceholderState.submitted;

  bool get isLocked => locked || (slot?.placeholder.isLocked ?? false);

  RowStatus get status {
    if (isLocked) return RowStatus.locked;
    switch (slot?.placeholder.state) {
      case ScorePlaceholderState.official:
        return RowStatus.official;
      case ScorePlaceholderState.submitted:
      case ScorePlaceholderState.inReview:
        return RowStatus.submitted;
      case ScorePlaceholderState.notEntered:
      case null:
        return RowStatus.notEntered;
    }
  }

  bool get isScored => slot?.officialScore != null;

  /// This row with a new saved [slot], after a save.
  ScoringRow withSlot(ScoreSlot slot) => ScoringRow(
    assignment: assignment,
    pilot: pilot,
    slot: slot,
    team: team,
    result: result,
    locked: locked,
  );
}
