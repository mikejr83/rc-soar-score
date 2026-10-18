import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_public/contest_routes.dart';
import 'package:soar_score_public/pages/results/contest_not_found_page.dart';

import 'support/fake_publication.dart';

void main() {
  const unknown = '019c0000-0000-7000-8000-0000000000ff';

  for (final id in [unknown, 'not-an-id']) {
    testWidgets('$id shows contest not found without changing the route', (
      tester,
    ) async {
      final router = await pumpContestRoutes(tester, contestResultsPath(id));
      expect(find.byType(ContestNotFoundPage), findsOneWidget);
      expect(find.text(ContestNotFoundPage.title), findsOneWidget);
      expect(
        find.textContaining('may not have been published yet'),
        findsOneWidget,
      );
      expect(router.state.uri.path, contestResultsPath(id));

      await tester.tap(find.text('Search contests'));
      await tester.pumpAndSettle();
      expect(find.text('contests stub'), findsOneWidget);
    });
  }
}
