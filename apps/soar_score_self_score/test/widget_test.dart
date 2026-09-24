import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/app.dart';

void main() {
  testWidgets('home page displays and navigates to score entry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SelfScoreApp());

    expect(find.text('Pilots enter flight scores here.'), findsOneWidget);

    await tester.tap(find.text('Enter Score'));
    await tester.pumpAndSettle();

    expect(find.text('Score entry form placeholder.'), findsOneWidget);

    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();

    expect(find.text('Pilots enter flight scores here.'), findsOneWidget);
  });
}
