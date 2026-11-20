import 'dart:math' as math;

import '../reports_facts.dart';

/// The options a CSV export honours, read from the same filter map the report
/// reads. The keys mirror the Overall Standings report (`from`/`to`, `pct`,
/// `raw`, `team`, `num`, `cls`) so the export matches what the viewer is
/// showing. A key the map leaves out takes its default.
class ScoreExportOptions {
  const ScoreExportOptions({
    required this.from,
    required this.requestedTo,
    required this.to,
    required this.lastShown,
    required this.rounds,
    required this.percentage,
    required this.raw,
    required this.team,
    required this.number,
    required this.pilotClass,
  });

  factory ScoreExportOptions.of(
    Map<String, String> filters,
    ReportsFacts facts,
  ) {
    bool on(String key, bool fallback) =>
        filters[key] == null ? fallback : filters[key] == '1';
    final provisional =
        provisionalApplies(facts) && on('prov', defaultProvisional(facts));
    final lastShown = facts.standingsRoundLimit(provisional: provisional);
    final from = int.tryParse(filters['from'] ?? '') ?? 1;
    final requestedTo =
        int.tryParse(filters['to'] ?? '') ?? facts.defaultStandingsRound;
    final ordinals = facts.roundOrdinals;
    final cap = requestedTo < lastShown ? requestedTo : lastShown;
    final to = ordinals.where((round) => round <= cap).fold(0, math.max);
    return ScoreExportOptions(
      from: from,
      requestedTo: requestedTo,
      to: to,
      lastShown: lastShown,
      rounds: [
        for (final round in ordinals)
          if (round >= from && round <= to) round,
      ],
      percentage: on('pct', true),
      raw: on('raw', false),
      team: facts.teamsEnabled && on('team', true),
      number: facts.numbersEnabled && on('num', false),
      pilotClass: facts.classesEnabled && on('cls', false),
    );
  }

  /// Provisional only means something while a round is partly scored or not
  /// flown, and never once the contest is completed.
  static bool provisionalApplies(ReportsFacts facts) =>
      !facts.isCompleted &&
      (facts.partlyScoredRounds > 0 || facts.notFlownRounds > 0);

  /// Provisional starts on while rounds are not (fully) scored yet.
  static bool defaultProvisional(ReportsFacts facts) =>
      provisionalApplies(facts);

  /// The filters that apply when the URL names none.
  static Map<String, String> defaults(ReportsFacts facts) => {
    'from': '1',
    'prov': defaultProvisional(facts) ? '1' : '0',
  };

  /// The first round exported.
  final int from;

  /// The upper bound the director chose, before it is held to [lastShown].
  final int requestedTo;

  /// The last round exported.
  final int to;

  /// The last round the export can show.
  final int lastShown;

  /// The rounds exported, ascending.
  final List<int> rounds;

  /// A percentage column (of the winner).
  final bool percentage;

  /// A raw column (total plus the dropped rounds).
  final bool raw;

  /// A team column.
  final bool team;

  /// A pilot number column.
  final bool number;

  /// A pilot class column.
  final bool pilotClass;

  /// The reason the range cannot be exported, or null when it can.
  String? check() {
    if (lastShown == 0 && requestedTo == 0) {
      return 'No standings are stored for the requested rounds.';
    }
    if (from > to || rounds.isEmpty) {
      final range = from == requestedTo ? '$from' : '$from–$requestedTo';
      return 'No rounds to export: nothing is scored in rounds $range.';
    }
    return null;
  }
}
