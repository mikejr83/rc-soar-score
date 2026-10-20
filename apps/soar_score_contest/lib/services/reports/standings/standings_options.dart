import '../reports_facts.dart';
import '../viewer/report_spec.dart';

/// The filters and options of the Overall Standings report, read from the
/// viewer's filter map (and so from the URL) with the contest's facts.
///
/// Filter keys: `from` and `to` (a round range), the options `pct`, `raw`,
/// `team`, `num` and `cls`, and the detail options `det` (flight details) and
/// `prov` (provisional). A key the URL leaves out takes its default.
class StandingsOptions {
  StandingsOptions._({
    required this.from,
    required this.requestedTo,
    required this.to,
    required this.lastShown,
    required this.provisional,
    required this.percentage,
    required this.raw,
    required this.team,
    required this.number,
    required this.pilotClass,
    required this.details,
  });

  factory StandingsOptions.of(Map<String, String> filters, ReportsFacts facts) {
    bool on(String key, bool fallback) =>
        filters[key] == null ? fallback : filters[key] == '1';
    final provisional = on('prov', defaultProvisional(facts));
    final lastShown = provisional
        ? facts.lastScoredRound
        : facts.lastFullyScoredRound;
    final from = int.tryParse(filters['from'] ?? '') ?? 1;
    // An unset To is the last round with any score, so the dropdown names a
    // real round; the sheet itself never goes past [lastShown].
    final requestedTo =
        int.tryParse(filters['to'] ?? '') ?? facts.lastScoredRound;
    return StandingsOptions._(
      from: from,
      requestedTo: requestedTo,
      to: requestedTo < lastShown ? requestedTo : lastShown,
      lastShown: lastShown,
      provisional: provisional,
      percentage: on('pct', true),
      raw: on('raw', false),
      team: facts.teamsEnabled && on('team', true),
      number: facts.numbersEnabled && on('num', false),
      pilotClass: facts.classesEnabled && on('cls', false),
      details: on('det', false),
    );
  }

  /// Provisional starts on while rounds are not (fully) scored yet, and off
  /// once every round is: then there is nothing partial to show.
  static bool defaultProvisional(ReportsFacts facts) =>
      facts.partlyScoredRounds > 0 || facts.notFlownRounds > 0;

  /// The filters that apply when the URL names none.
  static Map<String, String> defaults(ReportsFacts facts) => {
    'from': '1',
    'prov': defaultProvisional(facts) ? '1' : '0',
  };

  /// The first round shown.
  final int from;

  /// The upper bound the director chose, before it is held to [lastShown].
  final int requestedTo;

  /// The last round shown, and the round rank and total are as of.
  final int to;

  /// The last round the report can show: the last with any score when
  /// Provisional is on, else the last that is fully scored.
  final int lastShown;
  final bool provisional;

  final bool percentage;
  final bool raw;
  final bool team;
  final bool number;
  final bool pilotClass;

  /// Flight details under each round score.
  final bool details;

  /// Whether the sheet is a slice of the standings: a lower bound above round
  /// 1, or an upper bound below the last round shown.
  bool get isRange => from != 1 || to != lastShown;

  /// The round numbers shown, ascending.
  List<int> get rounds => [for (var r = from; r <= to; r++) r];

  /// Judges the range: invalid when the lower bound is above the upper one,
  /// empty when nothing in it can be shown.
  ReportCheck check(ReportsFacts facts) {
    if (from > requestedTo) {
      return const ReportInvalid(
        'From round must be on or before To round. The sheet still shows the '
        'last rounds that were valid.',
      );
    }
    if (from > lastShown) {
      final range = from == requestedTo ? '$from' : '$from–$requestedTo';
      final scored = facts.lastScoredRound;
      return ReportEmpty(
        title: 'No scores in rounds $range',
        body: provisional
            ? 'No scores have been entered in these rounds yet. Choose rounds '
                  '1 to $scored.'
            : (facts.lastFullyScoredRound == 0
                  ? 'No round is fully scored yet and Provisional is off. Turn '
                        'Provisional on to see the scores entered so far.'
                  : 'These rounds are not fully scored and Provisional is '
                        'off. Turn Provisional on, or choose rounds 1 to '
                        '${facts.lastFullyScoredRound}.'),
      );
    }
    return ReportCheck.ok;
  }

  /// The filters in a few words: "Rounds 1–6 · Provisional".
  String get summary {
    final range = from == to ? '$from' : '$from–$to';
    return 'Rounds $range${provisional ? ' · Provisional' : ''}';
  }
}
