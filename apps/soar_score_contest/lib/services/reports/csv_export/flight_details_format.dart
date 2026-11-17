import 'score_csv_format.dart';
import 'score_export_options.dart';
import 'score_export_source.dart';

/// The long Flight Details export: one row per flight, every flight in the
/// shown rounds, sorted by round, then group, then score. The [Selected]
/// column marks the flight that counts for the pilot's round; [Place] and
/// [Total] are repeated on each pilot's rows so a pivot on Pilot reproduces
/// the standings.
///
/// The detail columns follow the discipline: F5J shows Time, Height and
/// Landing; F3J and the other disciplines omit Height.
class FlightDetailsFormat extends ScoreCsvFormat {
  const FlightDetailsFormat(this.options);

  /// The options that decide which columns appear; the same filters the
  /// viewer is showing.
  final ScoreExportOptions options;

  @override
  String get name => 'Flight Details';

  @override
  String get fileExtension => 'csv';

  @override
  List<List<String?>> build(ScoreExportSource source) {
    final decimals = source.decimalPlaces;
    final hasHeight = source.hasLaunchHeight;
    final header = <String>[
      'Pilot',
      if (options.number) 'No.',
      if (options.team) 'Team',
      if (options.pilotClass) 'Class',
      'Round',
      'Group',
      'Time',
      if (hasHeight) 'Height',
      'Landing',
      'Raw',
      'Flight penalty',
      'Cumulative penalty',
      'Round score',
      'Selected',
      'Place',
      'Total',
    ];
    final rows = <List<String?>>[header];
    for (final flight in source.flights) {
      final cells = <String?>[
        flight.pilot.listName,
        if (options.number) _number(flight.pilot.number),
        if (options.team) flight.pilot.team,
        if (options.pilotClass) flight.pilot.className,
        '${flight.round}',
        flight.group,
        flight.seconds?.toString(),
        if (hasHeight) flight.height?.toString(),
        _num(flight.landing, decimals),
        _num(flight.raw, decimals),
        _num(flight.flightPenalty, decimals),
        _num(flight.cumulativePenalty, decimals),
        _num(flight.roundScore, decimals),
        flight.selected ? 'Yes' : 'No',
        flight.place?.toString(),
        _num(flight.total, decimals),
      ];
      rows.add(cells);
    }
    return rows;
  }

  static String? _num(double? value, int decimals) =>
      value?.toStringAsFixed(decimals);

  static String? _number(int? value) => value?.toString();
}
