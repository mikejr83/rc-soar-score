import 'score_csv_format.dart';
import 'score_export_options.dart';
import 'score_export_source.dart';

/// The long Flight Details export: one row per flight, every flight in the
/// shown rounds, sorted by round, then group, then score. The [Selected]
/// column marks the flight that counts for the pilot's round; [Place] and
/// [Total] are repeated on each pilot's rows so a pivot on Pilot reproduces
/// the standings.
///
/// The recorded launch height is always shown, for every discipline (in
/// metres); a discipline that does not record it simply leaves it empty.
class FlightDetailsFormat extends ScoreCsvFormat {
  const FlightDetailsFormat(this.options, {super.writeBom, super.hardenText});

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
    final header = <String>[
      'Pilot',
      if (options.number) 'No.',
      if (options.team) 'Team',
      if (options.pilotClass) 'Class',
      'Round',
      'Group',
      'Time (s)',
      'Height (m)',
      'Landing',
      'Flight raw',
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
        _text(flight.pilot.listName),
        if (options.number) _number(flight.pilot.number),
        if (options.team) _text(flight.pilot.team),
        if (options.pilotClass) _text(flight.pilot.className),
        '${flight.round}',
        flight.group,
        flight.seconds?.toString(),
        flight.height?.toString(),
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
