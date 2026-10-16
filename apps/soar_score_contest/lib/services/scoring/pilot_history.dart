import 'package:soar_score_core/soar_score_core.dart';

/// The history of one pilot's slot, for the group history view.
class PilotHistory {
  const PilotHistory({required this.pilot, required this.entries});

  final String pilot;
  final List<ScoreHistoryEntry> entries;
}
