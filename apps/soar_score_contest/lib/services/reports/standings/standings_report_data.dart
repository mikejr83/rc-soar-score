import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// What was recorded for one flight, for the Flight details lines. Each part
/// is `null` when it was not recorded, which is not the same as 0.
class FlightDetail {
  const FlightDetail({this.seconds, this.landing, this.height});

  /// Flight time in seconds.
  final int? seconds;

  /// Landing points.
  final double? landing;

  /// Launch height in metres.
  final int? height;
}

/// The server has no stored standing as of a round (it answers 400): nothing
/// was recalculated yet, so scores that exist have no standings.
class NoStoredStandings implements Exception {
  const NoStoredStandings(this.round);

  final int round;
}

/// What the Overall Standings report reads from the API for one filter set:
/// the stored standings as of a round, the selected flight of each round it
/// shows, and (when asked) what was recorded for each flight.
class StandingsReportData {
  StandingsReportData({
    required this.results,
    required this.flights,
    required this.details,
  });

  /// The standings as of the report's last round.
  final ContestResults results;

  /// The selected flight of each shown round: round ordinal, then pilot.
  final Map<int, Map<Id, FlightResult>> flights;

  /// Flight details by round and pilot; empty when not asked for.
  final Map<int, Map<Id, FlightDetail>> details;

  /// Reads the standings as of [asOf] and the flights of the given [rounds],
  /// which must be rounds that exist (a cancelled round has no results), in
  /// one request. With [withDetails] the same response carries the official
  /// scores for the Flight details lines. Any failed read is thrown, so a
  /// sheet is never built from part of its data.
  static Future<StandingsReportData> load(
    ApiClient client,
    Id contestId, {
    required List<int> rounds,
    required int asOf,
    required bool withDetails,
  }) async {
    final report = await client.reportData(
      contestId,
      facts: false,
      scores: withDetails,
      asOfRound: asOf,
      rounds: rounds,
    );
    final standings = report.results;
    if (standings == null) {
      throw NoStoredStandings(asOf);
    }
    final scores = report.scores;
    final components = {
      if (scores != null)
        for (final slot in scores.slots)
          if (slot.officialScore != null)
            slot.placeholder.id: slot.officialScore!.components,
    };
    final flights = <int, Map<Id, FlightResult>>{};
    final details = <int, Map<Id, FlightDetail>>{};
    for (var i = 0; i < rounds.length; i++) {
      final round = report.roundResults![i];
      final byPilot = <Id, FlightResult>{};
      for (final flight in round.flights) {
        if (flight.result.isSelected) {
          byPilot[flight.participationId] = flight.result;
        }
      }
      flights[rounds[i]] = byPilot;
      if (withDetails) {
        details[rounds[i]] = {
          for (final entry in byPilot.entries)
            entry.key: _detail(
              entry.value,
              components[entry.value.scorePlaceholderId],
            ),
        };
      }
    }
    return StandingsReportData(
      results: standings,
      flights: flights,
      details: details,
    );
  }

  static FlightDetail _detail(FlightResult flight, Map<String, Object?>? raw) =>
      FlightDetail(
        seconds: _int(raw?['time_flown']),
        landing: flight.landingPoints,
        height: _int(raw?['launch_height']),
      );

  static int? _int(Object? value) => value is num ? value.toInt() : null;
}
