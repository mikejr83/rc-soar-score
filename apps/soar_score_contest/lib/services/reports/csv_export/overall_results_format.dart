import 'score_csv_format.dart';
import 'score_export_options.dart';
import 'score_export_source.dart';

/// The wide Overall Results export: one row per pilot with a column per round.
/// The optional columns appear only when the matching option is on, and the
/// Penalty column appears only when some pilot has a deduction.
class OverallResultsFormat extends ScoreCsvFormat {
  const OverallResultsFormat(this.options);

  /// The options that decide which columns appear; the same filters the
  /// viewer is showing.
  final ScoreExportOptions options;

  @override
  String get name => 'Overall Results';

  @override
  String get fileExtension => 'csv';

  @override
  List<List<String?>> build(ScoreExportSource source) {
    final decimals = source.decimalPlaces;
    final header = <String>[
      'Rank',
      'Pilot',
      'Total',
      if (options.percentage) 'Pct',
      if (options.raw) 'Raw',
      if (options.team) 'Team',
      if (options.number) 'No.',
      if (options.pilotClass) 'Class',
      for (final round in source.rounds) 'R$round',
      if (source.standings.any((row) => row.penalty > 0)) 'Penalty',
    ];
    final rows = <List<String?>>[header];
    for (final row in source.standings) {
      final cells = <String?>[
        '${row.place}',
        row.pilot.listName,
        _num(row.total, decimals),
        if (options.percentage) _num(row.percentage, decimals),
        if (options.raw) _num(row.raw, decimals),
        if (options.team) row.pilot.team,
        if (options.number) _number(row.pilot.number),
        if (options.pilotClass) row.pilot.className,
        for (final round in source.rounds) _num(row.cells[round]?.score, decimals),
        if (source.standings.any((r) => r.penalty > 0)) _num(row.penalty, decimals),
      ];
      rows.add(cells);
    }
    return rows;
  }

  static String? _num(double? value, int decimals) =>
      value?.toStringAsFixed(decimals);

  static String? _number(int? value) => value?.toString();
}
