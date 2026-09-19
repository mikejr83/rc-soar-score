// Widget tests for the contest administration application shell.

import 'package:flutter_test/flutter_test.dart';

import 'package:soar_score_contest/main.dart';
import 'package:soar_score_contest/state/connectivity_state.dart';

void main() {
  group('ScoreSoarContest', () {
    testWidgets('App starts on the landing page', (tester) async {
      final connectivity = ConnectivityState();
      await tester.pumpWidget(ScoreSoarContest(connectivity: connectivity));

      expect(find.text('RC Soar Score'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
    });

    testWidgets('Development nav item opens the testing pages',
        (tester) async {
      final connectivity = ConnectivityState();
      await tester.pumpWidget(ScoreSoarContest(connectivity: connectivity));

      await tester.tap(find.byTooltip('Development testing pages'));
      await tester.pumpAndSettle();

      expect(find.text('Scoring Tests'), findsOneWidget);
    });
  });
}
