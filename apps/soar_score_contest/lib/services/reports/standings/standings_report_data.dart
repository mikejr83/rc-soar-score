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

  /// Reads the standings as of [asOf] and the flights of rounds [from] to
  /// [asOf]. With [withDetails] it also reads the official scores for the
  /// Flight details lines; a failure of that read leaves them `—`.
  static Future<StandingsReportData> load(
    ApiClient client,
    Id contestId, {
    required int from,
    required int asOf,
    required bool withDetails,
  }) async {
    final rounds = [for (var r = from; r <= asOf; r++) r];
    final results = await Future.wait<Object?>([
      client.results(contestId, asOfRound: asOf),
      for (final round in rounds) client.roundResults(contestId, round),
      if (withDetails) _scores(client, contestId),
    ]);
    final standings = results[0]! as ContestResults;
    final scores = withDetails ? results.last as ContestScores? : null;
    final components = {
      if (scores != null)
        for (final slot in scores.slots)
          if (slot.officialScore != null)
            slot.placeholder.id: slot.officialScore!.components,
    };
    final flights = <int, Map<Id, FlightResult>>{};
    final details = <int, Map<Id, FlightDetail>>{};
    for (var i = 0; i < rounds.length; i++) {
      final round = results[i + 1]! as RoundResults;
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

  static Future<ContestScores?> _scores(ApiClient client, Id id) async {
    try {
      return await client.scores(id);
    } on Object {
      return null;
    }
  }

  static FlightDetail _detail(FlightResult flight, Map<String, Object?>? raw) =>
      FlightDetail(
        seconds: _int(raw?['time_flown']),
        landing: flight.landingPoints,
        height: _int(raw?['launch_height']),
      );

  static int? _int(Object? value) => value is num ? value.toInt() : null;
}
