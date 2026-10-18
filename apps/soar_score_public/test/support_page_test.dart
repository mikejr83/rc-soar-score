import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_public/pages/support/support_page.dart';

void main() {
  const thankYou = 'Thank you. Your support request has been received.';

  Future<void> pumpForm(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SupportPage())),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
  }

  testWidgets('empty submit shows required errors and no thank-you', (
    tester,
  ) async {
    await pumpForm(tester);
    await submit(tester);

    // Name, email, request type and message are required; user type is not.
    expect(find.text('Required'), findsNWidgets(4));
    expect(find.text(thankYou), findsNothing);
  });

  testWidgets('filled form shows the thank-you state', (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Ann');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'ann@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Message'),
      'Hello',
    );

    await tester.tap(find.text('Request type'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('General Inquiry').last);
    await tester.pumpAndSettle();

    await submit(tester);

    expect(find.text('Required'), findsNothing);
    expect(find.text(thankYou), findsOneWidget);
  });
}
