import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/pages/landing_page.dart';

const _sizes = [
  Size(1280, 800),
  Size(800, 600),
  Size(600, 480),
  Size(400, 700),
  Size(360, 400),
];

void main() {
  group('landing page layout', () {
    for (final isWeb in [true, false]) {
      for (final size in _sizes) {
        testWidgets(
          'does not overflow at ${size.width.toInt()}x${size.height.toInt()}'
          ' (${isWeb ? 'web' : 'desktop'})',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
              MaterialApp(home: LandingPage(isWeb: isWeb)),
            );
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets('does not overflow with large text', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const LandingPage(isWeb: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('scrolls to the external links on a short window', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: LandingPage()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Public contest site'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Public contest site'), findsOneWidget);
    });
  });
}
