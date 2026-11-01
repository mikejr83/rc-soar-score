import '../draw_matrix/draw_matrix_options.dart';
import '../reports_facts.dart';
import '../viewer/report_spec.dart';

/// The filters and options of the Scoring Sheet, read from the viewer's filter
/// map (and so from the URL) with the contest's facts.
///
/// Filter keys: `from` and `to` (an inclusive round range, as in the Draw
/// Matrix), `club` (off by default), `team`, `num` and `cls` (the contest
/// columns, on), `val` (Validated, on), `ret` (include retired pilots, off) and
/// `pre` (Pre-fill, off). A key the URL leaves out takes its default.
class ScoringSheetOptions {
  ScoringSheetOptions._({
    required this.range,
    required this.clubChosen,
    required this.teamChosen,
    required this.numberChosen,
    required this.classChosen,
    required this.validated,
    required this.includeRetired,
    required this.prefillChosen,
    required this.teamsEnabled,
    required this.numbersEnabled,
    required this.classesEnabled,
    required this.hasScores,
    required this.retiredCount,
  });

  factory ScoringSheetOptions.of(
    Map<String, String> filters,
    ReportsFacts facts,
  ) {
    bool on(String key, bool fallback) =>
        filters[key] == null ? fallback : filters[key] == '1';
    return ScoringSheetOptions._(
      range: DrawMatrixOptions.of(filters, facts),
      clubChosen: on('club', false),
      teamChosen: on('team', true),
      numberChosen: on('num', true),
      classChosen: on('cls', true),
      validated: on('val', true),
      includeRetired: on('ret', false),
      prefillChosen: on('pre', false),
      teamsEnabled: facts.teamsEnabled,
      numbersEnabled: facts.numbersEnabled,
      classesEnabled: facts.classesEnabled,
      hasScores: facts.hasScores,
      retiredCount: facts.pilots.where((p) => p.isRetired).length,
    );
  }

  /// The filters that apply when the URL names none.
  static Map<String, String> defaults(ReportsFacts facts) => const {
    'from': '1',
  };

  /// The round range, with the Draw Matrix's rules.
  final DrawMatrixOptions range;

  final bool clubChosen;
  final bool teamChosen;
  final bool numberChosen;
  final bool classChosen;
  final bool validated;
  final bool includeRetired;
  final bool prefillChosen;

  final bool teamsEnabled;
  final bool numbersEnabled;
  final bool classesEnabled;
  final bool hasScores;

  /// The pilots who retired, whether or not they are shown.
  final int retiredCount;

  /// The contest columns the director keeps, each only when the contest uses
  /// it.
  bool get showClub => clubChosen;
  bool get showTeam => teamsEnabled && teamChosen;
  bool get showNumber => numbersEnabled && numberChosen;
  bool get showClass => classesEnabled && classChosen;

  /// Pre-fill needs a score to print; the choice is kept while there is none.
  bool get prefillAvailable => hasScores;
  bool get prefill => prefillChosen && prefillAvailable;

  /// The rounds shown.
  List<int> get rounds => range.rounds;

  /// Judges the round range.
  ReportCheck check() => range.check();

  /// The filters in a few words: "Rounds 1–6 · Pre-fill".
  String get summary => [
    range.summary,
    if (includeRetired && retiredCount > 0) 'With retired pilots',
    if (prefill) 'Pre-fill',
  ].join(' · ');
}
