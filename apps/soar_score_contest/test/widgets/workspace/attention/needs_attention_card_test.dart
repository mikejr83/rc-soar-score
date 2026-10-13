import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/attention/attention_item.dart';
import 'package:soar_score_contest/services/workspace/attention/needs_attention.dart';
import 'package:soar_score_contest/widgets/workspace/attention/needs_attention_card.dart';

const _missing = AttentionItem(
  kind: AttentionKind.missingScores,
  count: 4,
  title: '4 scores missing in finished rounds',
  detail: 'Round 1: 1, Round 2: 3',
  linkLabel: 'Open in Scoring',
  scoringRound: 1,
);

Future<List<AttentionItem>> _pump(
  WidgetTester tester,
  NeedsAttention attention, {
  double width = 640,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  VoidCallback? onRetry,
}) async {
  final opened = <AttentionItem>[];
  tester.view.physicalSize = Size(width, 1200);
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
            child: NeedsAttentionCard(
              attention: attention,
              onOpen: opened.add,
              onRetry: onRetry,
            ),
          ),
        ),
      ),
    ),
  );
  return opened;
}

void main() {
  testWidgets('a row shows the count, the title, the detail and a link', (
    tester,
  ) async {
    await _pump(tester, const NeedsAttention(items: [_missing]));

    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('4 scores missing in finished rounds'), findsOneWidget);
    expect(find.text('Round 1: 1, Round 2: 3'), findsOneWidget);
    expect(find.text('Open in Scoring'), findsOneWidget);
    expect(find.byKey(const ValueKey('attention-note')), findsNothing);
  });

  testWidgets('the link hands back its row', (tester) async {
    final opened = await _pump(tester, const NeedsAttention(items: [_missing]));

    await tester.tap(
      find.byKey(const ValueKey('attention-link-missingScores')),
    );

    expect(opened, [_missing]);
  });

  testWidgets('nothing to see says so, and only what it can verify', (
    tester,
  ) async {
    await _pump(tester, const NeedsAttention());

    expect(find.text('Nothing needs attention'), findsOneWidget);
    expect(
      find.text('Every finished round has all its scores.'),
      findsOneWidget,
    );
    expect(find.textContaining('review'), findsNothing);
    expect(find.textContaining('synced'), findsNothing);
  });

  testWidgets('an unreadable source is not an all-clear', (tester) async {
    var retried = 0;
    await _pump(
      tester,
      const NeedsAttention(complete: false),
      onRetry: () => retried++,
    );

    expect(find.text('Nothing needs attention'), findsNothing);
    expect(
      find.text('Needs attention could not be worked out'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('attention-retry')));
    expect(retried, 1);
  });

  testWidgets('rows plus an unreadable source say the list may be short', (
    tester,
  ) async {
    await _pump(
      tester,
      const NeedsAttention(items: [_missing], complete: false),
    );

    expect(find.text('This list may be incomplete'), findsOneWidget);
    expect(find.text('4 scores missing in finished rounds'), findsOneWidget);
  });

  for (final width in [320.0, 640.0]) {
    testWidgets('fits at $width wide with large text, light and dark', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        await _pump(
          tester,
          const NeedsAttention(items: [_missing]),
          width: width,
          textScale: 2,
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
      }
    });
  }
}
