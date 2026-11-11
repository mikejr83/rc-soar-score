import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/app_sync_provider.dart';
import 'package:soar_score_contest/services/sync/app_sync_state.dart';
import 'package:soar_score_contest/services/sync/sync_scope_summary.dart';
import 'package:soar_score_contest/widgets/sync/reload_on_sync.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/fake_app_sync.dart';

AppSyncState _synced(Map<SyncScopeKey, int> revisions) => AppSyncState(
  scopes: {
    for (final e in revisions.entries)
      e.key: SyncScopeSummary(dataRevision: e.value),
  },
);

Future<void> _pump(WidgetTester tester, FakeAppSync sync, Widget child) =>
    tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AppSyncInherited(sync: sync, child: child),
      ),
    );

void main() {
  final contest = ContestScopeKey(Id.create());
  final other = ContestScopeKey(Id.create());
  final account = DirectorScopeKey(Id.create());

  testWidgets('fires when its scope syncs, not for another scope', (
    tester,
  ) async {
    final sync = FakeAppSync();
    var calls = 0;
    await _pump(
      tester,
      sync,
      ReloadOnSync(
        scope: contest,
        onSynced: () => calls++,
        child: const SizedBox(),
      ),
    );

    sync.state = _synced({other: 1});
    await tester.pump();
    expect(calls, 0);

    sync.state = _synced({contest: 1});
    await tester.pump();
    expect(calls, 1);

    // The same sync reported again (another scope moved) is not news.
    sync.state = _synced({contest: 1, other: 2});
    await tester.pump();
    expect(calls, 1);

    sync.state = _synced({contest: 2});
    await tester.pump();
    expect(calls, 2);
  });

  testWidgets('what was synced before the page opened is not news', (
    tester,
  ) async {
    final sync = FakeAppSync(state: _synced({contest: 1}));
    var calls = 0;
    await _pump(
      tester,
      sync,
      ReloadOnSync(
        scope: contest,
        onSynced: () => calls++,
        child: const SizedBox(),
      ),
    );
    sync.state = _synced({contest: 1});
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('the account variant follows the account scope', (tester) async {
    final sync = FakeAppSync()..accountScope = account;
    var calls = 0;
    await _pump(
      tester,
      sync,
      ReloadOnSync.account(onSynced: () => calls++, child: const SizedBox()),
    );
    sync.state = _synced({contest: 1});
    await tester.pump();
    expect(calls, 0);

    sync.state = _synced({account: 1});
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('a build without sync never fires', (tester) async {
    final sync = FakeAppSync(available: false);
    var calls = 0;
    await _pump(
      tester,
      sync,
      ReloadOnSync(
        scope: contest,
        onSynced: () => calls++,
        child: const SizedBox(),
      ),
    );
    sync.state = _synced({contest: 1});
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('contest() leaves the child alone for an id that is not one', (
    tester,
  ) async {
    const child = SizedBox(key: ValueKey('child'));
    expect(
      ReloadOnSync.contest(contestId: 'nope', onSynced: () {}, child: child),
      same(child),
    );
  });

  testWidgets('the contests variant also follows every contest scope', (
    tester,
  ) async {
    final sync = FakeAppSync()..accountScope = account;
    var calls = 0;
    await _pump(
      tester,
      sync,
      ReloadOnSync.contests(onSynced: () => calls++, child: const SizedBox()),
    );
    // A contest scope the page has not seen before gets its first data.
    sync.state = _synced({other: 1});
    await tester.pump();
    expect(calls, 1);

    sync.state = _synced({other: 1, contest: 2});
    await tester.pump();
    expect(calls, 2);

    // The account's own data counts as well.
    sync.state = _synced({other: 1, contest: 2, account: 1});
    await tester.pump();
    expect(calls, 3);

    // Nothing changed: no news.
    sync.state = _synced({other: 1, contest: 2, account: 1});
    await tester.pump();
    expect(calls, 3);
  });
}
