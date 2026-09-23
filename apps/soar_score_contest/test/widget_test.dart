import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/app.dart';
import 'package:soar_score_contest/pages/contests_page.dart';
import 'package:soar_score_contest/pages/home_page.dart';

void main() {
  testWidgets('renders the home route and navigates to the contests route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SoarScoreContestApp());
    await tester.pumpAndSettle();

    expect(find.text(HomePage.title), findsOneWidget);
    expect(find.text('Home placeholder'), findsOneWidget);

    await tester.tap(find.text('Go to Contests'));
    await tester.pumpAndSettle();

    expect(find.text(ContestsPage.title), findsOneWidget);
    expect(find.text('Contests placeholder'), findsOneWidget);

    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();

    expect(find.text('Home placeholder'), findsOneWidget);
  });

  testWidgets('renders the theme and both placeholder routes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SoarScoreContestApp());
    await tester.pumpAndSettle();

    // Home route content.
    expect(find.byType(HomePage), findsOneWidget);

    // Navigate to the second placeholder route.
    await tester.tap(find.text('Go to Contests'));
    await tester.pumpAndSettle();

    expect(find.byType(ContestsPage), findsOneWidget);
  });
}
