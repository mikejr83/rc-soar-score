import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/sync/app_sync_state.dart';
import 'package:soar_score_contest/services/sync/sync_scope_summary.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/fake_app_sync.dart';
import '../support/matrix_test_support.dart';
import '../support/participants_page_support.dart';

Finder _class(int n) => find.descendant(
  of: find.byKey(ValueKey('class-${personParticipationId(n).value}')),
  matching: find.byType(TextField),
);

String _text(WidgetTester tester, Finder field) =>
    tester.widget<TextField>(field).controller!.text;

AppSyncState _changed(Id contest) => AppSyncState(
  scopes: {ContestScopeKey(contest): const SyncScopeSummary(dataRevision: 1)},
);

void main() {
  testWidgets('a sync shows a row changed elsewhere and keeps typed edits', (
    tester,
  ) async {
    final server = ParticipantsServer();
    final sync = FakeAppSync();
    await pumpParticipantsPage(tester, server, sync: sync);

    // Person 2 is edited here; person 1 changes on another device.
    await tester.enterText(_class(2), 'sportsman');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    server.changeElsewhere(1);

    sync.state = _changed(contestId);
    await tester.pumpAndSettle();

    expect(_text(tester, _class(1)), 'Expert');
    expect(_text(tester, _class(2)), 'sportsman');
    expect(find.text('Unsaved changes to 1 participant'), findsOneWidget);
  });
}
