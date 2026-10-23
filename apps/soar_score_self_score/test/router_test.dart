import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/router.dart';

void main() {
  testWidgets('routes follow the participant-scoring spec', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/contests/c1');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/contests/c1/team');
    expect(find.text('Team overview'), findsOneWidget);

    router.go('/contests/c1/results');
    await tester.pumpAndSettle();
    expect(find.text('Overall, pilots'), findsOneWidget);

    router.go('/contests/c1/pilots/12/rounds/4');
    await tester.pumpAndSettle();
    expect(find.text('Time flown'), findsOneWidget);
  });
}
