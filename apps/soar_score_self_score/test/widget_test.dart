import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/app.dart';

void main() {
  testWidgets('landing page signs in to the contests list', (tester) async {
    await tester.pumpWidget(const SelfScoreApp());

    expect(find.text('Score your flights at the field'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Is this you?'), findsOneWidget);
    expect(find.text('Spring Open'), findsWidgets);
  });
}
