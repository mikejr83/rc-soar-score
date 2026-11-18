import 'score_csv_format.dart';
import 'score_export_options.dart';
import 'score_export_source.dart';

/// The wide Overall Results export: one row per pilot with a column per round.
/// The optional columns appear only when the matching option is on, and the
/// Penalty column appears only when some pilot has a deduction.
class OverallResultsFormat extends ScoreCsvFormat {
  const OverallResultsFormat(this.options, {super.writeBom, super.hardenText});

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
    final hasPenalty = source.standings.any((row) => row.penalty > 0);
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
      if (hasPenalty) 'Penalty deducted',
    ];
    final rows = <List<String?>>[header];
    for (final row in source.standings) {
      final cells = <String?>[
        '${row.place}',
        _text(row.pilot.listName),
        _num(row.total, decimals),
        if (options.percentage) _num(row.percentage, decimals),
        if (options.raw) _num(row.raw, decimals),
        if (options.team) _text(row.pilot.team),
        if (options.number) _number(row.pilot.number),
        if (options.pilotClass) _text(row.pilot.className),
        for (final round in source.rounds)
          _roundCell(row.cells[round], decimals),
        if (hasPenalty) _num(row.penalty, decimals),
      ];
      rows.add(cells);
    }
    return rows;
  }

  /// A round score; a dropped round keeps its value with a `*` prefix, so a
  /// spreadsheet reader sees which round was dropped.
  String? _roundCell(ExportStandingsCell? cell, int decimals) {
    final score = cell?.score;
    if (score == null) {
      return null;
    }
    final text = score.toStringAsFixed(decimals);
    return cell!.dropped ? '*$text' : text;
  }

  String? _text(String? value) {
    if (value == null) {
      return null;
    }
    return hardenText ? ScoreCsvFormat.harden(value) : value;
  }

  static String? _num(double? value, int decimals) =>
      value?.toStringAsFixed(decimals);

  static String? _number(int? value) => value?.toString();
}
