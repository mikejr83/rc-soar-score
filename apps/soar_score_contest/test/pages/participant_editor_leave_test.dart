import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/app_mode_provider.dart';
import 'package:soar_score_contest/router.dart';

import '../support/participant_test_support.dart';

/// Pumps the real app router (shell, rail and header included) at [initial].
Future<void> _pump(WidgetTester tester, String initial) async {
  useTallWindow(tester);
  final router = buildAppRouter(
    initialLocation: initial,
    appMode: AppModeNotifier(isOfflineMode: true),
  );
  addTearDown(router.dispose);
  final client = clientFor((request) async {
    if (request.url.path.endsWith('/contests')) {
      return json({'contests': []});
    }
    return json({'participants': []});
  });
  await tester.pumpWidget(
    ApiClientInherited(
      client: client,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester) async {
  await tester.enterText(find.byKey(const ValueKey('first-name')), 'Ada');
  await tester.pump();
}

void main() {
  testWidgets('leaving through the rail with unsaved changes asks first', (
    tester,
  ) async {
    await _pump(tester, newParticipantPath);
    await _type(tester);

    await tester.tap(find.text('Contests').first);
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('first-name')), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
  });

  testWidgets('leaving through the Participants crumb asks first, and '
      'discarding leaves', (tester) async {
    await _pump(tester, newParticipantPath);
    await _type(tester);

    await tester.tap(find.byKey(const ValueKey('breadcrumb-participants')));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('first-name')), findsNothing);
    expect(find.text('No participants yet.'), findsOneWidget);
  });

  testWidgets('leaving without changes does not ask', (tester) async {
    await _pump(tester, newParticipantPath);

    await tester.tap(find.byKey(const ValueKey('breadcrumb-participants')));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('No participants yet.'), findsOneWidget);
  });
}
