import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';

import '../support/scoring_test_support.dart';

final _l10n = AppLocalizationsEn();

const _flight = {'time_flown': 540, 'launch_height': 120};

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  testWidgets('a waiting submission shows the Pilot entry indicator', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedPendingSubmission(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    expect(_key('score-indicator-pilot-entry-${first.value}'), findsOneWidget);
  });

  testWidgets('an official score from a pilot keeps the indicator', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final second = scoringAssignmentId(1, 2);
    final server = ScoringServer()
      ..seedScore(first, _flight, authority: Authority.participant)
      ..seedScore(second, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    expect(find.text(_l10n.scoreStatusOfficial), findsNWidgets(2));
    expect(_key('score-indicator-pilot-entry-${first.value}'), findsOneWidget);
    // A score the director typed has no source to point at.
    expect(_key('score-indicator-pilot-entry-${second.value}'), findsNothing);
  });

  testWidgets('a score the contest accepted automatically keeps it too', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedAutomaticScore(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    expect(_key('score-indicator-pilot-entry-${first.value}'), findsOneWidget);
  });

  testWidgets('the Review indicator stays hidden until review exists', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()
      ..seedPendingSubmission(first, _flight, inReview: true);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    expect(find.text('Review'), findsNothing);
    expect(_key('score-indicator-review-${first.value}'), findsNothing);
  });

  testWidgets('the indicator text is not cut off in its column', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedPendingSubmission(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    final text = tester.widget<Text>(find.text(_l10n.scorePilotEntryChip));
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);
  });
}
