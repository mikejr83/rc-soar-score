import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_public/models/results/contest_load_result.dart';
import 'package:soar_score_public/pages/results/contest_not_visible_page.dart';
import 'package:soar_score_public/pages/results/contest_page.dart';

void main() {
  const contestId = '019c0000-0000-7000-8000-000000000030';

  testWidgets('shows the private-mode message and re-checks every 15 minutes', (
    tester,
  ) async {
    var rechecks = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContestNotVisiblePage(onRecheck: () => rechecks++),
        ),
      ),
    );
    expect(find.text(ContestNotVisiblePage.message), findsOneWidget);
    expect(find.textContaining('every 15 minutes'), findsOneWidget);

    await tester.pump(const Duration(minutes: 14));
    expect(rechecks, 0);
    await tester.pump(const Duration(minutes: 1));
    expect(rechecks, 1);
    await tester.pump(const Duration(minutes: 15));
    expect(rechecks, 2);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the page shows it for a not-visible load result', (
    tester,
  ) async {
    // TODO(#463): today the server answers 404; this is the status the
    // loader will map once it is distinct.
    Future<PublicPublicationDto> loader(Id id) => throw ApiHttpError(
      'forbidden',
      statusCode: 403,
      body: '{"error":{"code":"contest_not_visible","message":"private"}}',
      requestUri: Uri.parse('http://fake/public/publications/${id.value}'),
    );
    expect(
      await ContestLoadResult.load(loader, contestId),
      isA<ContestNotVisible>(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContestPage(contestId: contestId, loader: loader),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ContestNotVisiblePage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
