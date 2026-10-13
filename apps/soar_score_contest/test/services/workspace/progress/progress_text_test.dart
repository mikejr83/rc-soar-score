import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/progress/progress_headline.dart';
import 'package:soar_score_contest/services/workspace/progress/progress_text.dart';

void main() {
  test('group 1 is A', () {
    expect(ProgressText.groupLetter(1), 'A');
    expect(ProgressText.groupLetter(26), 'Z');
    expect(ProgressText.groupLetter(27), '27');
  });

  test('the clock is in the contest time zone', () {
    final utc = DateTime.utc(2026, 10, 17, 19, 31);
    expect(ProgressText.clock(utc, 'UTC'), '19:31');
    // Mountain Daylight Time is UTC-6 on that date.
    expect(ProgressText.clock(utc, 'America/Denver'), '13:31');
  });

  test('the matrix line copes with uneven groups and a single round', () {
    const headline = ProgressHeadline(
      stage: ProgressStage.noScores,
      roundCount: 1,
      groupCount: 1,
      groupSizeMin: 5,
      groupSizeMax: 6,
      matrixRevision: 1,
    );
    expect(
      ProgressText.whereSub(headline, zoneId: 'UTC'),
      '1 round · 1 group of 5 to 6 · matrix revision 1',
    );
  });

  test('a latest score without a group leaves the group out', () {
    final headline = ProgressHeadline(
      stage: ProgressStage.inProgress,
      currentRound: 2,
      totalRounds: 8,
      latestScoreAt: DateTime.utc(2026, 10, 17, 9, 5),
    );
    expect(
      ProgressText.whereSub(headline, zoneId: 'UTC'),
      'latest accepted score 09:05',
    );
  });

  test('a partly flown completed contest says how many rounds', () {
    const headline = ProgressHeadline(
      stage: ProgressStage.finished,
      totalRounds: 8,
      roundsFlown: 6,
      scoreCount: 1,
    );
    expect(ProgressText.whereMain(headline), '6 of 8 rounds flown');
    expect(ProgressText.whereSub(headline, zoneId: 'UTC'), '1 score');
  });
}
