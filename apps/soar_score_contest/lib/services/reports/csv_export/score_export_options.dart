import 'dart:math' as math;

import '../reports_facts.dart';

/// The options a CSV export honours, read from the same filter map the report
/// reads. The keys mirror the Overall Standings report (`from`/`to`, `pct`,
/// `raw`, `team`, `num`, `cls`, `det`) so the export matches what the viewer
/// is showing. A key the map leaves out takes its default.
class ScoreExportOptions {
  const ScoreExportOptions({
    required this.from,
    required this.to,
    required this.rounds,
    required this.provisional,
    required this.percentage,
    required this.raw,
    required this.team,
    required this.number,
    required this.pilotClass,
    required this.details,
  });

  factory ScoreExportOptions.of(Map<String, String> filters, ReportsFacts facts) {
    bool on(String key, bool fallback) =>
        filters[key] == null ? fallback : filters[key] == '1';
    final provisional =
        provisionalApplies(facts) && on('prov', defaultProvisional(facts));
    // The last round the export can show: the last with any score when
    // Provisional is on, else the last that is fully scored.
    final lastShown = provisional
        ? facts.lastScoredRound
        : facts.lastFullyScoredRound;
    final from = int.tryParse(filters['from'] ?? '') ?? 1;
    final requestedTo =
        int.tryParse(filters['to'] ?? '') ?? facts.lastScoredRound;
    final ordinals = facts.roundOrdinals;
    final cap = requestedTo < lastShown ? requestedTo : lastShown;
    final to = ordinals.where((round) => round <= cap).fold(0, math.max);
    return ScoreExportOptions(
      from: from,
      to: to,
      rounds: [for (final round in ordinals)
        if (round >= from && round <= to) round],
      provisional: provisional,
      percentage: on('pct', true),
      raw: on('raw', false),
      team: facts.teamsEnabled && on('team', true),
      number: facts.numbersEnabled && on('num', false),
      pilotClass: facts.classesEnabled && on('cls', false),
      details: on('det', false),
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

  /// The last round exported.
  final int to;

  /// The rounds exported, ascending.
  final List<int> rounds;

  /// Whether the standings shown are provisional.
  final bool provisional;

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

  /// Flight details columns.
  final bool details;
}
