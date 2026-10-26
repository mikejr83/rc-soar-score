import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';

const _contest = 'Front Range F5J Open';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the status bar shows the storage and the sync status (#253)', (
    tester,
  ) async {
    await openMainPage(tester);

    // The web build keeps nothing on the device, so it has no storage
    // indicator and no sync entry.
    if (kIsWeb) {
      expect(find.byKey(const ValueKey('storage-chip')), findsNothing);
      return;
    }

    // The storage indicator is part of the bar on every shell page.
    final storage = find.byKey(const ValueKey('storage-chip'));
    await pumpUntilFound(tester, storage);
    await pumpUntilFound(tester, find.text('Local storage · Available'));

    // Its detail view says when the storage was last read and can check again.
    await tapVisible(tester, storage);
    await pumpUntilFound(tester, find.text('Status: Available'));
    expect(find.textContaining('Last observed: '), findsOneWidget);
    expect(find.text('Last observed: Never'), findsNothing);
    await tapVisible(tester, find.byKey(const ValueKey('storage-retry')));
    await pumpUntilFound(tester, find.text('Status: Available'));
    await tapVisible(tester, find.text('OK'));

    // Outside a contest the bar has no sync entry.
    final bar = find.byKey(const ValueKey('contest-status-bar'));
    final sync = find.descendant(
      of: bar,
      matching: find.byKey(const ValueKey('shell-sync-status')),
    );
    expect(sync, findsNothing);

    // Inside a contest the bar tells the sync status and opens its details.
    await openContest(tester, _contest);
    await pumpUntilFound(tester, sync);
    await tapVisible(tester, sync);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('sync-details-card')),
    );
  });
}
