import 'package:soar_score_core/soar_score_core.dart';

import '../../new_contest/date_range_text.dart';

/// The words on a card that come from the contest.
abstract final class PilotCardsText {
  /// The small line across the top of every card: contest, venue and dates, so
  /// a loose card is traceable to its contest.
  static String contestLine(Contest contest) {
    final place = [
      if (contest.city case final city? when city.trim().isNotEmpty) city,
      if (contest.state case final state? when state.trim().isNotEmpty) state,
    ].join(', ');
    final start = ContestTime.inZone(contest.startDateTime, contest.timezone);
    final end = ContestTime.inZone(contest.endDateTime, contest.timezone);
    return [
      contest.name,
      if (place.isNotEmpty) place,
      dateRangeText(start, end),
    ].join(' · ');
  }

  /// The card footer: the matrix revision and the rounds covered, so a card
  /// printed before a redraw is recognisable as old. With Pre-fill on it adds
  /// how far the scores go and, when any value is not official, the legend.
  static String footer({
    required int? matrixRevision,
    required List<int> rounds,
    required int drawn,
    required int planned,
    required int? scoredThrough,
    required bool anyUnofficial,
  }) {
    final range = rounds.isEmpty
        ? 'No rounds'
        : rounds.length == 1
        ? 'Round ${rounds.first}'
        : 'Rounds ${rounds.first} to ${rounds.last}';
    return [
      if (matrixRevision != null) 'Matrix rev $matrixRevision',
      if (planned > drawn) '$range ($drawn of $planned drawn)' else range,
      if (scoredThrough != null) 'Includes scores through round $scoredThrough',
      if (scoredThrough != null && anyUnofficial) '* not official',
    ].join(' · ');
  }
}
