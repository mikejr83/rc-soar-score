import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft.dart';
import 'package:soar_score_contest/services/new_contest/draft_persistence.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/stored_draft.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Start fresh opens a blank wizard and deletes the stored draft', (
    tester,
  ) async {
    await openMainPage(tester);
    final persistence = draftStoreOf(tester).persistence!;
    await storeDraftFromEarlierRun(
      persistence,
      const ContestDraft(name: 'E2E Stored Draft', venue: 'E2E Field'),
    );
    expect(await storedDraft(persistence), isA<FoundStoredDraft>());

    await tapVisible(tester, find.byKey(const ValueKey('create-contest')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('resume-draft-dialog')),
    );
    await tapVisible(tester, find.byKey(const ValueKey('resume-draft-fresh')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('contest-name')));

    expect(find.text('E2E Stored Draft'), findsNothing);
    expect(await storedDraft(persistence), isA<NoStoredDraft>());
  });
}
