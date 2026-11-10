import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/app.dart';

void main() {
  testWidgets('landing page offers the director link and defers accounts', (
    tester,
  ) async {
    await tester.pumpWidget(const SelfScoreApp());

    expect(find.text('Score your flights at the field'), findsOneWidget);
    expect(
      find.textContaining('Open the link your contest director sent'),
      findsOneWidget,
    );

    // Accounts come in a future release, so the buttons stay disabled.
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Sign in'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Sign up'),
          )
          .onPressed,
      isNull,
    );
    expect(find.textContaining('coming in a future release'), findsOneWidget);
  });
}
