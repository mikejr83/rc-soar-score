import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';
import 'support/pump_until_gone.dart';

/// A running demo contest: some flights unscored and a round not flown.
const _running = 'Mountain States Team F5J';

/// A ready demo contest, which cannot be completed yet.
const _ready = 'Front Range F5J Open';

Finder _key(String key) => find.byKey(ValueKey(key));

/// The text of the status summary value [id].
String _status(WidgetTester tester, String id) =>
    tester.widget<Text>(_key('status-$id-value')).data!;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The demo database is recreated on each launch, so completing the contest
  // here does not leak into other journeys.
  testWidgets('contest state controls on the workspace (#250)', (tester) async {
    await openMainPage(tester);
    await openContest(tester, _running);
    await pumpUntilFound(tester, _key('status-summary'));

    // The status summary labels each state on its own.
    expect(_status(tester, 'lifecycle'), 'Running');
    expect(_key('status-deletion'), findsNothing);
    for (final id in [
      'scoring',
      'administration',
      'publication',
      'results',
      'archive',
    ]) {
      expect(_key('status-$id-value'), findsOneWidget);
    }

    // Participant scoring: whichever way it is now, the other control flips it.
    final opening = _key('control-openScoring').evaluate().isNotEmpty;
    final wasOpen = _status(tester, 'scoring');
    await tapVisible(
      tester,
      _key(opening ? 'control-openScoring' : 'control-closeScoring'),
    );
    await pumpUntilFound(
      tester,
      _key(opening ? 'control-closeScoring' : 'control-openScoring'),
    );
    expect(_status(tester, 'scoring'), isNot(wasOpen));

    // Locking asks first, and cancel changes nothing.
    expect(_status(tester, 'administration'), 'Unlocked');
    await tapVisible(tester, _key('control-lock'));
    await pumpUntilFound(tester, _key('lock-dialog'));
    expect(find.text('• Contest configuration'), findsOneWidget);
    await tester.tap(_key('lock-dialog-cancel'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_status(tester, 'administration'), 'Unlocked');

    await tapVisible(tester, _key('control-lock'));
    await pumpUntilFound(tester, _key('lock-dialog'));
    await tester.tap(_key('lock-dialog-confirm'));
    await pumpUntilFound(tester, _key('control-unlock'));
    expect(_status(tester, 'administration'), 'Locked');
    // The next-step card names who locked and when, from the audit trail (#345).
    await pumpUntilFound(
      tester,
      find.textContaining(
        'administration locked by you at',
        findRichText: true,
      ),
    );

    await tapVisible(tester, _key('control-unlock'));
    await pumpUntilFound(tester, _key('control-lock'));
    expect(_status(tester, 'administration'), 'Unlocked');

    // Completing lists what is still open; the demo has both kinds.
    await tapVisible(tester, _key('control-complete'));
    await pumpUntilFound(tester, _key('complete-dialog'));
    await pumpUntilFound(tester, _key('complete-dialog-missing'));
    expect(_key('complete-dialog-unflown'), findsOneWidget);
    await tester.tap(_key('complete-dialog-confirm'));
    await pumpUntilGone(tester, _key('complete-dialog'));
    await pumpUntilFound(tester, find.text('Completed'));
    expect(_status(tester, 'lifecycle'), 'Completed');
    expect(_status(tester, 'scoring'), 'Closed');
    // The next-step card dates the completion from the audit trail (#345).
    await pumpUntilFound(
      tester,
      find.textContaining('The contest was completed'),
    );
    expect(
      tester.widget<FilledButton>(_key('control-complete')).onPressed,
      isNull,
    );
    expect(_key('control-lifecycle-reason'), findsOneWidget);

    // A contest that is not running yet explains why it cannot be completed.
    await tapVisible(tester, _key('breadcrumb-contests'));
    await openContest(tester, _ready);
    await pumpUntilFound(tester, _key('status-summary'));
    expect(
      tester.widget<FilledButton>(_key('control-complete')).onPressed,
      isNull,
    );
    expect(
      tester.widget<Text>(_key('control-lifecycle-reason')).data,
      contains('Only a running contest can be completed'),
    );
  });
}
