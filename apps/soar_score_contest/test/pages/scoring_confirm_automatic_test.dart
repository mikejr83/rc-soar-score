import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:soar_score_contest/l10n/app_localizations_en.dart';

import '../support/matrix_test_support.dart';
import '../support/scoring_test_support.dart';

final _words = AppLocalizationsEn();

const _flight = {'time_flown': 540, 'launch_height': 120};

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _openHistory(WidgetTester tester, int pilot) async {
  await tester.tap(_key('row-menu-${scoringAssignmentId(1, pilot).value}'));
  await tester.pumpAndSettle();
  await tester.tap(_key('menu-history'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an automatic score says so and offers Confirm', (tester) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()
      ..seedAutomaticScore(first, _flight)
      ..seedScore(scoringAssignmentId(1, 2), _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    // Only the automatic row has the chip and the button; a director's score
    // stays plain Official.
    expect(find.text(_words.scoreAcceptedAutomatically), findsOneWidget);
    expect(find.text('Official'), findsOneWidget);
    expect(find.text(_words.scoreConfirm), findsOneWidget);
    expect(_key('score-confirm-automatic-${first.value}'), findsOneWidget);
    expect(_key('score-automatic-note-${first.value}'), findsOneWidget);
  });

  for (final scale in [1.0, 1.5]) {
    testWidgets('the automatic chip wraps in its column and is never cut off '
        'at text scale $scale', (tester) async {
      final first = scoringAssignmentId(1, 1);
      final server = ScoringServer()..seedAutomaticScore(first, _flight);
      await pumpScoringPage(
        tester,
        server,
        round: 1,
        group: 1,
        textScale: scale,
      );

      final label = find.descendant(
        of: _key('score-row-${first.value}'),
        matching: find.text(_words.scoreAcceptedAutomatically),
      );
      expect(label, findsOneWidget);
      // An ellipsis would hide the qualifier; the label wraps instead.
      expect(tester.widget<Text>(label).overflow, isNot(TextOverflow.ellipsis));
      final paragraph = tester.renderObject<RenderParagraph>(label);
      expect(paragraph.didExceedMaxLines, isFalse);
      // Flutter's test font is not the app font, so widths are not measured
      // here; a layout overflow would still surface as an exception.
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Confirm sends the official score and ends as Official', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedAutomaticScore(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await tester.tap(_key('score-confirm-automatic-${first.value}'));
    await tester.pumpAndSettle();

    // No second version is entered; only the decision is sent.
    expect(server.entries, isEmpty);
    expect(server.confirmedAssignments, [first]);
    expect(server.promotedBodies.single['expected_score_revision'], 1);
    expect(find.text(_words.scoreAcceptedAutomatically), findsNothing);
    expect(find.text('Official'), findsOneWidget);
    expect(find.text(_words.scoreConfirm), findsNothing);
  });

  testWidgets('a busy server shows Retry for Confirm, which asks again', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedAutomaticScore(first, _flight);
    server.promoteFailures[first] = (503, 'contest_busy');
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await tester.tap(_key('score-confirm-automatic-${first.value}'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not confirm.'), findsOneWidget);
    // Nothing was stored; the row is still waiting for a decision.
    expect(find.text(_words.scoreAcceptedAutomatically), findsOneWidget);

    server.promoteFailures.clear();
    await tester.tap(_key('score-retry'));
    await tester.pumpAndSettle();

    expect(server.confirmedAssignments, [first]);
    expect(find.text(_words.scoreAcceptedAutomatically), findsNothing);
  });

  testWidgets(
    'a score corrected meanwhile shows the newer score, with nothing to confirm',
    (tester) async {
      final first = scoringAssignmentId(1, 1);
      final server = ScoringServer()..seedAutomaticScore(first, _flight);
      await pumpScoringPage(tester, server, round: 1, group: 1);
      // Another director corrects the score before the tap arrives.
      server.seedCorrection(first, {'time_flown': 500}, 'Timer misread');

      await tester.tap(_key('score-confirm-automatic-${first.value}'));
      await tester.pumpAndSettle();

      // The row now shows the newer, director-entered score and has nothing
      // left to confirm.
      expect(find.text('8:20'), findsWidgets);
      expect(find.text(_words.scoreAcceptedAutomatically), findsNothing);
      expect(find.text(_words.scoreConfirm), findsNothing);
      expect(server.confirmedAssignments, isEmpty);
    },
  );

  testWidgets('typed edits turn Confirm off and say what to do', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedAutomaticScore(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await tester.tap(_key('score-row-${first.value}'));
    await tester.pumpAndSettle();
    await tester.enterText(_key('score-height-${first.value}'), '99');
    await tester.pumpAndSettle();

    final button = tester.widget<TextButton>(
      _key('score-confirm-automatic-${first.value}'),
    );
    expect(button.onPressed, isNull);
    expect(find.byTooltip('Save or revert your edits first.'), findsOneWidget);
    expect(find.text('Save or revert your edits first.'), findsNothing);
  });

  testWidgets('history names the system, and the confirmation', (tester) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedAutomaticScore(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await _openHistory(tester, 1);
    expect(
      find.text(
        _words.scoreHistoryMadeOfficialBy(_words.scoreHistoryAutomatic),
      ),
      findsOneWidget,
    );
    expect(find.text(_words.scoreHistoryConfirmed), findsNothing);
    await tester.tap(_key('score-history-close'));
    await tester.pumpAndSettle();

    await tester.tap(_key('score-confirm-automatic-${first.value}'));
    await tester.pumpAndSettle();
    await _openHistory(tester, 1);
    expect(
      find.text(
        _words.scoreHistoryMadeOfficialBy(_words.scoreHistoryAutomatic),
      ),
      findsOneWidget,
    );
    expect(find.text(_words.scoreHistoryConfirmed), findsOneWidget);
  });

  testWidgets('a director\'s own score shows no automatic wording', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedScore(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    expect(find.text(_words.scoreAcceptedAutomatically), findsNothing);
    expect(find.text(_words.scoreConfirm), findsNothing);
    await _openHistory(tester, 1);
    expect(find.textContaining('System (automatic)'), findsNothing);
  });

  testWidgets('a retired pilot keeps the score and has no Confirm', (
    tester,
  ) async {
    final second = scoringAssignmentId(1, 2);
    final server = ScoringServer()..seedAutomaticScore(second, _flight);
    // Bo retired at round 1 after the contest accepted their entry.
    server.matrixServer.retirements[2] = 1;
    await pumpScoringPage(tester, server, round: 1, group: 1);

    expect(find.text('Retired from round 1'), findsOneWidget);
    expect(find.text('1 of 2 entered · 1 official'), findsOneWidget);
    expect(find.text('9:00'), findsWidgets);
    expect(find.text(_words.scoreConfirm), findsNothing);
    expect(_key('score-confirm-automatic-${second.value}'), findsNothing);
    expect(server.promoteRequests, 0);
  });

  testWidgets('a queued Confirm says confirm, and blocks a repeat', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()
      ..seedAutomaticScore(first, _flight)
      ..queuePromotions.add(first);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await tester.tap(_key('score-confirm-automatic-${first.value}'));
    await tester.pumpAndSettle();

    expect(server.promoteRequests, 1);
    expect(find.text(_words.scoreConfirmWaiting), findsOneWidget);
    expect(find.text(_words.scoreConfirmQueued('Ann Lee')), findsOneWidget);
    expect(find.text(_words.scoreAdoptionWaiting), findsNothing);
    // Nothing more to ask while the service decides.
    expect(_key('score-confirm-automatic-${first.value}'), findsNothing);
  });

  testWidgets('a changed score whose reload fails still words it as Confirm', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedAutomaticScore(first, _flight);
    server.promoteFailures[first] = (409, 'stale_revision');
    await pumpScoringPage(tester, server, round: 1, group: 1);
    server.readFailure = 503;

    await tester.tap(_key('score-confirm-automatic-${first.value}'));
    await tester.pumpAndSettle();

    expect(find.text(_words.scoreConfirmReloadFailed), findsOneWidget);
    expect(find.textContaining('Not marked official'), findsNothing);
  });

  testWidgets('a locked automatic score says so and offers no Confirm', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer(matrix: drawnMatrix(lockedGroups: {(1, 1)}))
      ..seedAutomaticScore(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    expect(find.text(_words.scoreAutomaticLocked), findsOneWidget);
    expect(find.text(_words.scoreAutomaticNote), findsNothing);
    expect(_key('score-confirm-automatic-${first.value}'), findsNothing);
  });
}
