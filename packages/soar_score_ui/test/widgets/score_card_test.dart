import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

void main() {
  group('ScoreCard', () {
    testWidgets('renders title with a body and trailing widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ScoreCard(
                title: 'Flight 3',
                subtitle: 'Round 1',
                trailing: const Text('91.5'),
                child: const Text('Best of 7 flights'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Flight 3'), findsOneWidget);
      expect(find.text('Round 1'), findsOneWidget);
      expect(find.text('91.5'), findsOneWidget);
      expect(find.text('Best of 7 flights'), findsOneWidget);
    });

    testWidgets('renders title only when subtitle, trailing, and body are omitted', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: ScoreCard(title: 'Pilot A'))),
        ),
      );

      expect(find.text('Pilot A'), findsOneWidget);
    });

    testWidgets('onTap fires when a handler is provided', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ScoreCard(title: 'Flight 1', onTap: () => taps++),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ScoreCard));
      expect(taps, 1);
    });

    testWidgets('onTap is inert when no handler is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: ScoreCard(title: 'Flight 1'))),
        ),
      );

      await tester.tap(find.byType(ScoreCard));
      expect(tester.takeException(), isNull);
    });
  });
}
