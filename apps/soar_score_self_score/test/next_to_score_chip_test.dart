import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/models/pilot_round.dart';
import 'package:soar_score_self_score/widgets/pilot_round_card.dart';

void main() {
  testWidgets(
    'the Next to score chip is outlined, not a filled button (#924)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: PilotRoundCard(
              round: const PilotRound(
                number: 2,
                group: 'A',
                status: PilotRoundStatus.nextToScore,
              ),
              nextRound: 2,
              onEnter: () {},
              onView: () {},
              onFlightResults: () {},
            ),
          ),
        ),
      );
      final chip = find.ancestor(
        of: find.text('Next to score'),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration is ShapeDecoration,
        ),
      );
      final decoration =
          (tester.widget<Container>(chip.first).decoration! as ShapeDecoration);
      expect(decoration.color, isNull);
      expect(find.widgetWithText(FilledButton, 'Enter'), findsOneWidget);
    },
  );
}
