import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'fixture_files.dart';

PilotRounds _pilot(Map<String, Object?> p) => PilotRounds(
  pilotId: p['id'] as String,
  retiredAtRound: p['retired_at_round'] as int?,
  scores: [
    for (final r in asMaps(p['rounds']))
      RoundScore(
        round: r['round'] as int,
        groupScore: asDouble(r['group_score']),
        rawScore: asDouble(r['raw_score']),
        nonDroppable: r['non_droppable'] == true,
        cumulativePenalty: asDouble(r['cumulative_penalty'] ?? 0),
        underReview: r['under_review'] == true,
      ),
  ],
);

void main() {
  for (final fixture in loadF5jFixtures('contests.json')) {
    test(fixture['name'] as String, () {
      final options = asMap(fixture['options']);
      final asOf = fixture['as_of_round'] as int;
      final tieBreaker = options['tie_breaker_enabled'] == true;

      final totals = [
        for (final p in asMaps(fixture['pilots']))
          calculateContestTotal(
            _pilot(p),
            asOfRound: asOf,
            options: ContestTotalOptions(
              dropAfterRounds: [
                ...(options['drop_after_rounds'] as List).cast<int>(),
              ],
            ),
          ),
      ];

      final expected = asMap(fixture['expected']);
      final expectedTotals = asMaps(expected['totals']);
      expect(totals.length, expectedTotals.length);
      for (var i = 0; i < totals.length; i++) {
        final t = totals[i];
        final e = expectedTotals[i];
        final reason = e['id'] as String;
        expect(t.pilotId, e['id']);
        expect(
          t.rawTotal,
          closeTo(asDouble(e['raw_total']), 1e-9),
          reason: reason,
        );
        expect(
          t.droppedRounds,
          (e['dropped_rounds'] as List).cast<int>(),
          reason: reason,
        );
        expect(t.skippedDrops, e['skipped_drops'], reason: reason);
        expect(
          t.penaltyTotal,
          closeTo(asDouble(e['penalty_total']), 1e-9),
          reason: reason,
        );
        expect(
          t.overallScore,
          closeTo(asDouble(e['overall_score']), 1e-9),
          reason: reason,
        );
        expect(t.isPreliminary, e['is_preliminary'], reason: reason);
      }

      final ranking = rankPilots(totals, tieBreakerEnabled: tieBreaker);
      expect(
        [for (final p in ranking.places) (p.pilotId, p.place, p.isTied)],
        [
          for (final p in asMaps(expected['places']))
            (p['id'], p['place'], p['is_tied']),
        ],
      );

      final teams = fixture['teams'];
      if (teams == null) return;
      final places = rankTeams(
        [
          for (final t in asMaps(teams))
            TeamEntry(
              teamId: t['id'] as String,
              pilotIds: (t['pilots'] as List).cast<String>(),
            ),
        ],
        totals,
        ranking,
        pilotCount: fixture['team_pilot_count'] as int,
      );
      final expectedTeams = asMaps(expected['teams']);
      expect(places.length, expectedTeams.length);
      for (var i = 0; i < places.length; i++) {
        final e = expectedTeams[i];
        expect(places[i].teamId, e['id']);
        expect(places[i].place, e['place'], reason: places[i].teamId);
        expect(places[i].isTied, e['is_tied'], reason: places[i].teamId);
        expect(places[i].total, closeTo(asDouble(e['total']), 1e-9));
        expect(
          places[i].countedPilotIds,
          (e['counted_pilots'] as List).cast<String>(),
        );
        expect(places[i].isPreliminary, e['is_preliminary']);
      }
    });
  }
}
