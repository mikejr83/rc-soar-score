import 'package:soar_score_api/soar_score_api.dart';

import 'contest_header.dart';
import 'pilot_standing_row.dart';

/// A published contest parsed once from [PublicPublicationDto]; widgets read
/// this, never the raw maps.
class PublishedContest {
  PublishedContest._(
    this.header,
    this._participants,
    this._scores,
    this._standings,
  );

  factory PublishedContest.fromDto(
    PublicPublicationDto dto, {
    DateTime Function() now = DateTime.now,
  }) {
    final participants = <String, Map<String, Object?>>{};
    for (final entry in dto.participants.cast<Map<String, Object?>>()) {
      participants[entry['pilot_key'] as String] = entry;
    }
    // One flight per pilot per round counts; a reflight replaces it.
    final scores = <(int, String), Map<String, Object?>>{};
    for (final score in dto.scores.cast<Map<String, Object?>>()) {
      final key = (score['round'] as int, score['pilot_key'] as String);
      if (score['selected'] != false || !scores.containsKey(key)) {
        scores[key] = score;
      }
    }
    final standings = <int, List<Map<String, Object?>>>{};
    final rounds = (dto.standings['rounds'] as List<Object?>?) ?? const [];
    for (final round in rounds.cast<Map<String, Object?>>()) {
      standings[round['as_of_round']
          as int] = ((round['pilots'] as List<Object?>?) ?? const [])
          .cast<Map<String, Object?>>();
    }
    return PublishedContest._(
      ContestHeader.fromJson(dto.contest, now: now),
      participants,
      scores,
      standings,
    );
  }

  final ContestHeader header;
  final Map<String, Map<String, Object?>> _participants;
  final Map<(int, String), Map<String, Object?>> _scores;
  final Map<int, List<Map<String, Object?>>> _standings;

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
}
