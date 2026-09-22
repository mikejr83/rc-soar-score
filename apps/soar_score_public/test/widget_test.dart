import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_public/app.dart';
import 'package:soar_score_public/pages/site/docs_page.dart';
import 'package:soar_score_public/pages/site/help_page.dart';
import 'package:soar_score_public/pages/site/landing_page.dart';
import 'package:soar_score_public/pages/results/results_page.dart';

void main() {
  testWidgets('landing route renders; site routes and results route render too',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SoarScorePublicApp());
    await tester.pumpAndSettle();

    // Landing (site home) route content.
    expect(find.byType(LandingPage), findsOneWidget);
    expect(find.text(LandingPage.title), findsOneWidget);
    expect(find.text('Landing placeholder'), findsOneWidget);

    // Docs site route.
    await tester.tap(find.text('Docs'));
    await tester.pumpAndSettle();

    expect(find.byType(DocsPage), findsOneWidget);
    expect(find.text('Docs placeholder'), findsOneWidget);

    // Help site route.
    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();

    expect(find.byType(HelpPage), findsOneWidget);
    expect(find.text('Help placeholder'), findsOneWidget);

    // Results route.
    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Results'));
    await tester.pumpAndSettle();

    expect(find.byType(ResultsPage), findsOneWidget);
    expect(find.text('Results placeholder'), findsOneWidget);
  });
}
