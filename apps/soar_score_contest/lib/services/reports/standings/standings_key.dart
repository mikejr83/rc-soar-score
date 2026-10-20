import 'standings_layout.dart';
import 'standings_table.dart';

/// The key under each page of the standings and the lines that say where it
/// continues. Everything that needs explaining on this page is explained on
/// this page, so a reader never has to find another.
abstract final class StandingsKey {
  /// The key items for [page].
  static List<String> items({
    required StandingsTable table,
    required StandingsPageSpec page,
    required Map<int, String> partialRounds,
  }) {
    final options = table.options;
    return [
      '* = dropped round (shaded)',
      '— = no score',
      for (final round in page.rounds)
        if (partialRounds[round] case final partial?)
          'R$round partial: $partial',
      if (options.details)
        table.isF3j
            ? 'Flight details: time m:ss, landing points; — = not recorded'
            : 'Flight details: time m:ss, landing points, launch height; '
                  '— = not recorded',
      if (page.isFirstSet && options.percentage)
        'Pct = total as % of the winner',
      if (page.isFirstSet && options.raw) 'Raw = total plus dropped rounds',
      if (page.penalty) 'Penalty: deducted from the total, not dropped',
      if (table.hasTie) 'Tied pilots share a rank',
    ];
  }

  /// "Rounds 6 to 14 continue on page 3", or `null` on the last set.
  static String? continuation({
    required StandingsPageSpec page,
    required StandingsLayout layout,
  }) {
    final next = layout.continuationOf(page);
    if (next == null) {
      return null;
    }
    final text = roundsText(next.rounds, penalty: next.penalty);
    return '$text ${next.rounds.length > 1 ? 'continue' : 'continues'} on '
        'page ${next.number}';
  }

  /// "Pilots 1 to 11 · Rounds 1 to 5".
  static String indicator({required StandingsPageSpec page}) =>
      'Pilots ${page.pilotStart + 1} to ${page.pilotEnd} · '
      '${roundsText(page.rounds, penalty: page.penalty && page.rounds.isEmpty)}'
      '${page.penalty && page.rounds.isNotEmpty ? ' + Penalty' : ''}';

  /// "Round 5", "Rounds 1 to 5" or "Penalty" for no round columns.
  static String roundsText(List<int> rounds, {bool penalty = false}) {
    if (rounds.isEmpty) {
      return penalty ? 'Penalty' : 'No rounds';
    }
    return rounds.length == 1
        ? 'Round ${rounds.first}'
        : 'Rounds ${rounds.first} to ${rounds.last}';
  }
}
