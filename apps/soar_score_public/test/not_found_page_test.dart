import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_public/app.dart';
import 'package:soar_score_public/pages/site/landing_page.dart';
import 'package:soar_score_public/pages/site/not_found_page.dart';
import 'package:soar_score_public/widgets/site_shell.dart';

void main() {
  testWidgets('unknown route shows the not-found page in the shell', (
    tester,
  ) async {
    await tester.pumpWidget(const SoarScorePublicApp());
    await tester.pumpAndSettle();

    GoRouter.of(tester.element(find.byType(LandingPage))).go('/no-such-page');
    await tester.pumpAndSettle();

    expect(find.byType(SiteShell), findsOneWidget);
    expect(find.byType(NotFoundPage), findsOneWidget);
    expect(find.text(NotFoundPage.title), findsOneWidget);
    expect(find.textContaining('/no-such-page'), findsOneWidget);

    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();
    expect(find.byType(LandingPage), findsOneWidget);
  });
}
