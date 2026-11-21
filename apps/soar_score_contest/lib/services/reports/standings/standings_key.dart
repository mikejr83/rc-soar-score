import '../../../l10n/app_localizations.dart';
import 'standings_layout.dart';
import 'standings_table.dart';

/// The key under each page of the standings and the lines that say where it
/// continues. Everything that needs explaining on this page is explained on
/// this page, so a reader never has to find another.
abstract final class StandingsKey {
  /// The key items for [page].
  static List<String> items(
    AppLocalizations l10n, {
    required StandingsTable table,
    required StandingsPageSpec page,
    required Map<int, String> partialRounds,
  }) {
    final options = table.options;
    return [
      l10n.standingsKeyDropped,
      l10n.standingsKeyNoScore,
      for (final round in page.rounds)
        if (partialRounds[round] case final partial?)
          l10n.standingsKeyPartial(round, partial),
      if (options.details)
        table.isF3j
            ? l10n.standingsKeyFlightDetails
            : l10n.standingsKeyFlightDetailsHeight,
      if (page.isFirstSet && options.percentage) l10n.standingsKeyPct,
      if (page.isFirstSet && options.raw) l10n.standingsKeyRaw,
      if (page.penalty) l10n.standingsKeyPenalty,
      if (table.hasTie) l10n.standingsKeyTied,
    ];
  }

  /// "Rounds 6 to 14 continue on page 3", or `null` on the last set.
  static String? continuation(
    AppLocalizations l10n, {
    required StandingsPageSpec page,
    required StandingsLayout layout,
  }) {
    final next = layout.continuationOf(page);
    if (next == null) {
      return null;
    }
    final text = roundsText(l10n, next.rounds, penalty: next.penalty);
    return next.rounds.length > 1
        ? l10n.standingsContinuePage(text, next.number)
        : l10n.standingsContinuesPage(text, next.number);
  }

  /// "Pilots 1 to 11 · Rounds 1 to 5".
  static String indicator(
    AppLocalizations l10n, {
    required StandingsPageSpec page,
  }) =>
      l10n.standingsIndicator(
        page.pilotStart + 1,
        page.pilotEnd,
        roundsText(
          l10n,
          page.rounds,
          penalty: page.penalty && page.rounds.isEmpty,
        ),
      ) +
      (page.penalty && page.rounds.isNotEmpty
          ? l10n.standingsIndicatorPenalty
          : '');

  /// "Round 5", "Rounds 1 to 5" or "Penalty" for no round columns.
  static String roundsText(
    AppLocalizations l10n,
    List<int> rounds, {
    bool penalty = false,
  }) {
    if (rounds.isEmpty) {
      return penalty
          ? l10n.standingsKeyRoundsPenalty
          : l10n.standingsKeyRoundsNone;
    }
    return rounds.length == 1
        ? l10n.standingsRoundSemantic(rounds.first)
        : l10n.standingsKeyRoundsRange(rounds.first, rounds.last);
  }
}
