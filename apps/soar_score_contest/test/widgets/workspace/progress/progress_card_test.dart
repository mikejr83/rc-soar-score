import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/current_group_facts.dart';
import 'package:soar_score_contest/services/workspace/progress/progress_headline.dart';
import 'package:soar_score_contest/services/workspace/progress/progress_summary.dart';
import 'package:soar_score_contest/widgets/workspace/progress/progress_card.dart';

import '../../../support/progress_summary_support.dart';

const _groupB = CurrentGroupFacts(
  roundOrdinal: 3,
  groupNumber: 2,
  scored: 2,
  total: 6,
);

ProgressSummary _running() => deriveProgress(
  progressRounds([23, 21, 13, 0, 0, 0, 0, 0]),
  frontierGroup: _groupB,
  latestScoreAt: DateTime.utc(2026, 10, 17, 13, 31),
);

Future<List<int>> _pump(
  WidgetTester tester,
  ProgressSummary summary, {
  double width = 640,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  VoidCallback? onRetry,
}) async {
  final opened = <int>[];
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: brightness,
        colorSchemeSeed: Colors.blue,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: ProgressCard(
              summary: summary,
              zoneId: 'UTC',
              onOpenRound: opened.add,
              onRetry: onRetry,
            ),
          ),
        ),
      ),
    ),
  );
  return opened;
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key))).data!;

void main() {
  testWidgets('the headline names the round, the group and the time', (
    tester,
  ) async {
    await _pump(tester, _running());

    expect(_text(tester, 'progress-where'), 'Round 3 of 8');
    expect(
      _text(tester, 'progress-where-sub'),
      'Group B of 4 · latest accepted score 13:31',
    );
  });

  testWidgets('each tile says its state in words', (tester) async {
    await _pump(tester, _running());

    expect(find.text('Round 1'), findsOneWidget);
    expect(find.text('23/24'), findsOneWidget);
    expect(find.text('1 missing'), findsOneWidget);
    expect(find.text('3 missing'), findsOneWidget);
    expect(find.text('13/24'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Not flown'), findsNWidgets(5));
  });

  testWidgets('the lag note explains late entries', (tester) async {
    await _pump(tester, _running());

    expect(find.byKey(const ValueKey('progress-lag')), findsOneWidget);
    expect(
      find.textContaining('4 of 6 pilots haven’t entered scores yet'),
      findsOneWidget,
    );
  });

  testWidgets('no lag note when the group is complete', (tester) async {
    await _pump(
      tester,
      deriveProgress(
        progressRounds([24, 13]),
        frontierGroup: const CurrentGroupFacts(
          roundOrdinal: 2,
          groupNumber: 1,
          scored: 6,
          total: 6,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('progress-lag')), findsNothing);
  });

  testWidgets('a tile opens its round', (tester) async {
    final opened = await _pump(tester, _running());

    await tester.tap(find.byKey(const ValueKey('progress-tile-2')));
    await tester.tap(find.byKey(const ValueKey('progress-tile-6')));

    expect(opened, [2, 6]);
  });

  testWidgets('a tile can be opened from the keyboard', (tester) async {
    final opened = await _pump(tester, _running());

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    expect(opened, [1]);
  });

  testWidgets('a round that is not drawn is not a button', (tester) async {
    final opened = await _pump(
      tester,
      deriveProgress(
        progressRounds([24, 24, 24, 24]),
        seeded: true,
        intended: 8,
      ),
    );

    expect(find.text('Not drawn'), findsNWidgets(4));
    expect(find.text('—'), findsNWidgets(4));
    await tester.tap(
      find.byKey(const ValueKey('progress-tile-6')),
      warnIfMissed: false,
    );
    expect(opened, isEmpty);
  });

  testWidgets('a tile reads as a button with its full state', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _running());

    expect(
      find.bySemanticsLabel(
        'Round 3: In progress, 13 of 24 pilots scored. Open in Scoring.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Round 2: 3 scores missing, 21 of 24 pilots scored. Open in Scoring.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Round 6: Not flown. Open in Scoring.'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('no matrix shows the empty state', (tester) async {
    await _pump(
      tester,
      const ProgressSummary(
        headline: ProgressHeadline(stage: ProgressStage.noMatrix),
      ),
    );

    expect(find.text('No matrix yet'), findsOneWidget);
    expect(
      find.text('Round progress appears here once the matrix is drawn.'),
      findsOneWidget,
    );
  });

  testWidgets('unavailable scores offer Retry', (tester) async {
    var retried = 0;
    await _pump(
      tester,
      deriveProgress(const [], scoresAvailable: false),
      onRetry: () => retried++,
    );

    expect(find.text('Round progress could not be loaded.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('progress-retry')));
    expect(retried, 1);
  });

  testWidgets('a completed contest shows the final headline', (tester) async {
    await _pump(
      tester,
      deriveProgress(
        progressRounds(List.filled(8, 24)),
        completed: true,
        scoreCount: 192,
      ),
    );

    expect(find.text('Final'), findsOneWidget);
    expect(_text(tester, 'progress-where'), 'All 8 rounds flown');
    expect(_text(tester, 'progress-where-sub'), '192 scores');
  });

  testWidgets('before any score the headline describes the matrix', (
    tester,
  ) async {
    await _pump(tester, deriveProgress(progressRounds(List.filled(8, 0))));

    expect(_text(tester, 'progress-where'), 'No scores yet');
    expect(
      _text(tester, 'progress-where-sub'),
      '8 rounds · 4 groups of 6 · matrix revision 2',
    );
  });

  for (final width in [360.0, 640.0, 1100.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('ten rounds fit at $width wide and ${scale}x text', (
        tester,
      ) async {
        await _pump(
          tester,
          deriveProgress(
            progressRounds([24, 24, 23, 24, 13, 0, 0, 0, 0, 0]),
            frontierGroup: _groupB,
            latestScoreAt: DateTime.utc(2026, 10, 17, 15, 2),
          ),
          width: width,
          textScale: scale,
        );

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('progress-tile-10')), findsOneWidget);
      });
    }
  }

  testWidgets('renders in the dark theme', (tester) async {
    await _pump(tester, _running(), brightness: Brightness.dark);

    expect(tester.takeException(), isNull);
    expect(find.text('Round 3 of 8'), findsOneWidget);
  });
}
