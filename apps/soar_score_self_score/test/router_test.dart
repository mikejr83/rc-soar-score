import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/router.dart';

void main() {
  testWidgets('routes follow the participant-scoring spec', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/contests/spring-open');
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/contests/spring-open/team',
    );
    expect(find.text('Team overview'), findsOneWidget);

    router.go('/contests/spring-open/results');
    await tester.pumpAndSettle();
    expect(find.text('Overall, pilots'), findsOneWidget);

    router.go('/contests/spring-open/results?round=3');
    await tester.pumpAndSettle();
    expect(
      find.textContaining('viewing results as of round 3', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('4th'), findsOneWidget);

    router.go('/contests/spring-open/pilots/12');
    await tester.pumpAndSettle();
    expect(find.text('Next to score'), findsOneWidget);
    expect(find.text('Enter'), findsOneWidget);
    expect(find.text('View'), findsNWidgets(3));
    expect(
      find.text('Score round 4 first. Rounds open in order.'),
      findsWidgets,
    );

    router.go('/contests/spring-open/pilots/12/rounds/4');
    await tester.pumpAndSettle();
    expect(find.text('Time flown'), findsOneWidget);
    expect(find.text('All rounds for Jane Smith'), findsOneWidget);

    router.go('/contests/spring-open/pilots/12/rounds/4/group');
    await tester.pumpAndSettle();
    expect(find.text('Zero: out of bounds'), findsOneWidget);
    expect(find.text('No score yet'), findsOneWidget);
    expect(find.text('(you)'), findsOneWidget);
  });
}
