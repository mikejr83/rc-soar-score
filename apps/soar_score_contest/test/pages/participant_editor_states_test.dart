import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/app_sync_provider.dart';
import 'package:soar_score_contest/pages/participant_editor_page.dart';
import 'package:soar_score_contest/services/participants/participant_field.dart';
import 'package:soar_score_contest/services/sync/no_app_sync.dart';

import '../support/participant_test_support.dart';

void main() {
  testWidgets('managed fields are read-only with an explanation', (
    tester,
  ) async {
    useTallWindow(tester);
    final existing = profile('Ada', 'Lovelace');
    await tester.pumpWidget(
      editorApp(
        clientFor((_) async => json(existing.toJson())),
        ParticipantEditorPage(
          participantId: existing.id.value,
          managedFields: const {
            ParticipantField.firstName,
            ParticipantField.lastName,
            ParticipantField.email,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final first = tester.widget<TextField>(
      find.byKey(const ValueKey('first-name')),
    );
    expect(first.readOnly, isTrue);
    expect(
      find.text(
        'Managed by the participant. Only they can change it from their '
        'account.',
      ),
      findsNWidgets(3),
    );
    // Club is the first editable field and stays editable.
    expect(
      tester.widget<TextField>(find.byKey(const ValueKey('club'))).readOnly,
      isFalse,
    );
  });

  testWidgets('remote matching unavailable says the check was local', (
    tester,
  ) async {
    useTallWindow(tester);
    await tester.pumpWidget(
      editorApp(
        clientFor((_) async => json({'participants': []})),
        const ParticipantEditorPage(remoteMatchingUnavailable: true),
      ),
    );
    await tester.pumpAndSettle();
    await enterField(tester, 'email', 'sam@example.com');
    await leaveField(tester, 'email');
    await tester.pumpAndSettle();

    expect(
      find.text('Couldn’t check for matches online. Checked this device only.'),
      findsOneWidget,
    );
  });

  testWidgets('the storage chip appears only when the build syncs', (
    tester,
  ) async {
    useTallWindow(tester);
    final existing = profile('Ada', 'Lovelace');
    await tester.pumpWidget(
      AppSyncInherited(
        sync: const NoAppSync(),
        child: editorApp(
          clientFor((_) async => json(existing.toJson())),
          ParticipantEditorPage(participantId: existing.id.value),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Synced'), findsNothing);
    expect(find.text('Local only, not yet synced'), findsNothing);
  });

  testWidgets('a phone width stacks the fields and keeps the bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      editorApp(
        clientFor((_) async => json({'participants': []})),
        const ParticipantEditorPage(),
      ),
    );
    await tester.pumpAndSettle();

    final first = tester.getRect(find.byKey(const ValueKey('first-name')));
    final last = tester.getRect(find.byKey(const ValueKey('last-name')));
    expect(last.top, greaterThan(first.bottom));
    expect(find.byKey(const ValueKey('cancel-participant')), findsOneWidget);
    expect(find.byKey(const ValueKey('save-participant')), findsOneWidget);
  });

  testWidgets('a wide window puts the names side by side', (tester) async {
    useTallWindow(tester);
    await tester.pumpWidget(
      editorApp(
        clientFor((_) async => json({'participants': []})),
        const ParticipantEditorPage(),
      ),
    );
    await tester.pumpAndSettle();

    final first = tester.getRect(find.byKey(const ValueKey('first-name')));
    final last = tester.getRect(find.byKey(const ValueKey('last-name')));
    expect(last.left, greaterThan(first.right));
    expect(last.top, first.top);
  });
}
