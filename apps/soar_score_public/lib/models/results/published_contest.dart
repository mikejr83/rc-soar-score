import 'package:soar_score_api/soar_score_api.dart';

import 'contest_header.dart';
import 'flight_group.dart';
import 'flight_score_row.dart';
import 'pilot_standing_row.dart';
import 'team_standing_row.dart';

/// A published contest parsed once from [PublicPublicationDto]; widgets read
/// this, never the raw maps.
class PublishedContest {
  PublishedContest._(
    this.header,
    this.disciplineType,
    this._participants,
    this._scores,
    this._flights,
    this._standings,
    this._teams,
    this._teamStandings,
  );

  factory PublishedContest.fromDto(
    PublicPublicationDto dto, {
    DateTime Function() now = DateTime.now,
  }) {
    final participants = <String, Map<String, Object?>>{};
    for (final entry in dto.participants.cast<Map<String, Object?>>()) {
      participants[entry['pilot_key'] as String] = entry;
    }
    // One flight per pilot per round counts; a reflight replaces it. The
    // flight groups view shows every flight, so those are kept per round too.
    final scores = <(int, String), Map<String, Object?>>{};
    final flights = <int, List<Map<String, Object?>>>{};
    for (final score in dto.scores.cast<Map<String, Object?>>()) {
      final key = (score['round'] as int, score['pilot_key'] as String);
      if (score['selected'] != false || !scores.containsKey(key)) {
        scores[key] = score;
      }
      flights.putIfAbsent(key.$1, () => []).add(score);
    }
    final standings = <int, List<Map<String, Object?>>>{};
    final teamStandings = <int, List<Map<String, Object?>>>{};
    final rounds = (dto.standings['rounds'] as List<Object?>?) ?? const [];
    for (final round in rounds.cast<Map<String, Object?>>()) {
      final asOf = round['as_of_round'] as int;
      standings[asOf] = ((round['pilots'] as List<Object?>?) ?? const [])
          .cast<Map<String, Object?>>();
      teamStandings[asOf] = ((round['teams'] as List<Object?>?) ?? const [])
          .cast<Map<String, Object?>>();
    }
    return PublishedContest._(
      ContestHeader.fromJson(dto.contest, now: now),
      dto.disciplineType,
      participants,
      scores,
      flights,
      standings,
      dto.teams.cast<Map<String, Object?>>(),
      teamStandings,
    );
  }

  final ContestHeader header;

  /// The projection's `discipline_type`, for example `F5J`.
  final String disciplineType;
  final Map<String, Map<String, Object?>> _participants;
  final Map<(int, String), Map<String, Object?>> _scores;
  final Map<int, List<Map<String, Object?>>> _flights;
  final Map<int, List<Map<String, Object?>>> _standings;
  final List<Map<String, Object?>> _teams;
  final Map<int, List<Map<String, Object?>>> _teamStandings;

  /// True when the contest has teams; the team view redirects otherwise.
  bool get hasTeams => _teams.isNotEmpty;

  /// The rounds that have standings, ascending.
  List<int> get rounds => _standings.keys.toList()..sort();

  /// The highest-numbered round with standings, or null before any scores.
  int? get latestRound => rounds.lastOrNull;

  /// The Overall Individual Results as of [round]: by place, then by last
  /// name for tied pilots. Empty when [round] has no standings.
  List<PilotStandingRow> rowsAsOf(int round) {
    final pilots = _standings[round];
    if (pilots == null) return const [];
    final winner = pilots
        .map((p) => (p['overall_score'] as num).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);
    final rows = [for (final p in pilots) _row(p, round, winner)];
    rows.sort((a, b) {
      final byPlace = a.place.compareTo(b.place);
      if (byPlace != 0) return byPlace;
      final byLast = a.lastName.compareTo(b.lastName);
      return byLast != 0 ? byLast : a.firstName.compareTo(b.firstName);
    });
    return rows;
  }

  PilotStandingRow _row(Map<String, Object?> p, int round, double winner) {
    final key = p['pilot_key'] as String;
    final details =
        _participants[key]?['details'] as Map<String, Object?>? ?? const {};
    final overall = (p['overall_score'] as num).toDouble();
    return PilotStandingRow(
      pilotKey: key,
      place: p['place'] as int,
      isTied: p['tied'] == true,
      firstName: details['first_name'] as String? ?? '',
      lastName: details['last_name'] as String? ?? '',
      country: details['country'] as String? ?? '',
      overallScore: overall,
      percentOfWinner: winner > 0 ? overall / winner * 100 : 0,
      rawTotal: (p['raw_total'] as num).toDouble(),
      roundScores: {
        for (var r = 1; r <= round; r++)
          if (_scores[(r, key)]?['group_score'] case final num score)
            r: score.toDouble(),
      },
      droppedRounds: {
        for (final r in (p['dropped_rounds'] as List<Object?>?) ?? const [])
          r as int,
      },
      penaltyTotal: (p['penalty_total'] as num? ?? 0).toDouble(),
    );
  }

  /// The Team Scores as of [round]: teams by place, each with its pilots
  /// that have a standing as of [round], by their individual place.
  List<TeamStandingRow> teamRowsAsOf(int round) {
    final standings = _teamStandings[round];
    if (standings == null || standings.isEmpty) return const [];
    final pilots = {for (final p in rowsAsOf(round)) p.pilotKey: p};
    final winner = standings
        .map((t) => (t['team_score'] as num).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);
    final rows = <TeamStandingRow>[];
    for (final s in standings) {
      final key = s['team_key'] as String;
      final team = _teams.firstWhere(
        (t) => t['team_key'] == key,
        orElse: () => const {},
      );
      final score = (s['team_score'] as num).toDouble();
      rows.add(
        TeamStandingRow(
          teamKey: key,
          place: s['place'] as int,
          isTied: s['tied'] == true,
          name: team['name'] as String? ?? key,
          teamScore: score,
          percentOfWinner: winner > 0 ? score / winner * 100 : 0,
          pilots: [
            for (final p in (team['pilots'] as List<Object?>?) ?? const [])
              ?pilots[p],
          ]..sort((a, b) => a.place.compareTo(b.place)),
        ),
      );
    }
    rows.sort((a, b) {
      final byPlace = a.place.compareTo(b.place);
      return byPlace != 0 ? byPlace : a.name.compareTo(b.name);
    });
    return rows;
  }

  /// The flight groups of [round] by group number, a re-flight after the
  /// group it reflies. Empty when [round] has no flights.
  List<FlightGroup> flightGroupsOf(int round) {
    final groups = <(int, int?), List<FlightScoreRow>>{};
    for (final f in _flights[round] ?? const <Map<String, Object?>>[]) {
      // TODO(#457): `reflight` is this page's provisional name for the
      // re-flight ordinal on a score entry; rename once the server emits it.
      final reflight = switch (f['reflight']) {
        final int n when n > 0 => n,
        true => 1,
        _ => null,
      };
      groups
          .putIfAbsent((f['group'] as int, reflight), () => [])
          .add(_flight(f));
    }
    final keys = groups.keys.toList()
      ..sort((a, b) {
        final byGroup = a.$1.compareTo(b.$1);
        return byGroup != 0 ? byGroup : (a.$2 ?? 0).compareTo(b.$2 ?? 0);
      });
    return [
      for (final key in keys)
        FlightGroup(
          round: round,
          group: key.$1,
          reflight: key.$2,
          flights: groups[key]!
            ..sort((a, b) => b.groupScore.compareTo(a.groupScore)),
        ),
    ];
  }

  FlightScoreRow _flight(Map<String, Object?> f) {
    final key = f['pilot_key'] as String;
    final details =
        _participants[key]?['details'] as Map<String, Object?>? ?? const {};
    final name = '${details['first_name'] ?? ''} ${details['last_name'] ?? ''}'
        .trim();
    return FlightScoreRow(
      pilotKey: key,
      name: name.isEmpty ? 'Pilot withheld' : name,
      country: details['country'] as String? ?? '',
      outcome: f['outcome'] as String? ?? '',
      // TODO(#456): `raw_components` is this page's provisional name for the
      // discipline's raw inputs on a score entry; rename once the server
      // emits them.
      rawComponents: (f['raw_components'] as Map<String, Object?>?) ?? const {},
      landingPoints: (f['landing_points'] as num? ?? 0).toDouble(),
      rawPoints: (f['raw_points'] as num? ?? 0).toDouble(),
      groupScore: (f['group_score'] as num? ?? 0).toDouble(),
      penaltyPoints: (f['penalty_points'] as num? ?? 0).toDouble(),
      isSelected: f['selected'] != false,
    );
  }
}
