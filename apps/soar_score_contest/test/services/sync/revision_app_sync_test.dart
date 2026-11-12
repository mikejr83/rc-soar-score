import 'dart:async';

import 'package:fake_async/fake_async.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/sync/revision_app_sync.dart';
import 'package:soar_score_contest/services/sync/sync_problem.dart';
import 'package:soar_score_core/soar_score_core.dart';

final _account = Id.parse('019c0000-0000-7000-8000-000000000001');
final _contest = Id.parse('019c0000-0000-7000-8000-00000000c001');

class _SignedIn extends ChangeNotifier {
  bool value = true;

  void set(bool next) {
    value = next;
    notifyListeners();
  }
}

class _Service {
  final calls = <Id?>[];
  final sequences = <Id?, int>{};
  Object? failure;

  Future<SyncRevisionDto> fetch({Id? contestId}) async {
    calls.add(contestId);
    final failure = this.failure;
    if (failure != null) throw failure;
    return SyncRevisionDto(
      accountId: _account,
      contestId: contestId,
      sequence: sequences[contestId] ?? 0,
    );
  }
}

void main() {
  late _Service service;
  late _SignedIn signedIn;
  late RevisionAppSync sync;
  final contestScope = ContestScopeKey(_contest);
  SyncScopeKey accountScope() => sync.accountScope!;

  void withSync(
    void Function(FakeAsync async) body, {
    bool startSignedIn = true,
  }) {
    fakeAsync((async) {
      service = _Service();
      signedIn = _SignedIn()..value = startSignedIn;
      sync = RevisionAppSync(
        fetch: service.fetch,
        isSignedIn: () => signedIn.value,
        signInChanges: signedIn,
        jitter: 0,
        now: () => async.getClock(DateTime.utc(2026, 11, 11)).now(),
      );
      body(async);
      unawaited(sync.close());
      async.flushMicrotasks();
    });
  }

  int revisionOf(SyncScopeKey scope) => sync.state.of(scope)?.dataRevision ?? 0;

  test('is a refresh and not a sync', () {
    withSync((async) {
      expect(sync.available, isFalse);
      expect(sync.refreshable, isTrue);
    });
  });

  test('signing in looks at the director\'s data and offers its scope', () {
    withSync((async) {
      async.flushMicrotasks();

      expect(service.calls, [null]);
      expect(sync.accountScope, isNotNull);
      expect(sync.state.of(accountScope())?.lastSyncedAt, isNotNull);
      // The first look reloads pages that loaded before it.
      expect(revisionOf(accountScope()), 1);
    });
  });

  test('does nothing while nobody is signed in', () {
    withSync(startSignedIn: false, (async) {
      async.elapse(const Duration(hours: 1));

      expect(service.calls, isEmpty);
      expect(sync.accountScope, isNull);
    });
  });

  test('a contest in front is checked every five minutes', () {
    withSync((async) {
      async.flushMicrotasks();
      sync.focusChanged(_contest.value);
      async.flushMicrotasks();
      service.calls.clear();

      async.elapse(const Duration(minutes: 5));

      expect(service.calls, [_contest, null]);
    });
  });

  test(
    'outside a contest the director\'s data is checked every ten minutes',
    () {
      withSync((async) {
        async.flushMicrotasks();
        service.calls.clear();

        async.elapse(const Duration(minutes: 9));
        expect(service.calls, isEmpty);
        async.elapse(const Duration(minutes: 1));

        expect(service.calls, [null]);
      });
    },
  );

  test('a changed number moves the revision and an unchanged one does not', () {
    withSync((async) {
      async.flushMicrotasks();
      sync.focusChanged(_contest.value);
      async.flushMicrotasks();
      expect(revisionOf(contestScope), 1);

      async.elapse(const Duration(minutes: 5));
      expect(revisionOf(contestScope), 1);

      service.sequences[_contest] = 3;
      async.elapse(const Duration(minutes: 5));
      expect(revisionOf(contestScope), 2);

      async.elapse(const Duration(minutes: 5));
      expect(revisionOf(contestScope), 2);
    });
  });

  test('Refresh reloads even when nothing changed', () {
    withSync((async) {
      async.flushMicrotasks();
      sync.focusChanged(_contest.value);
      async.flushMicrotasks();

      unawaited(sync.syncNow(contestScope));
      async.flushMicrotasks();

      expect(revisionOf(contestScope), 2);
    });
  });

  test('a click and a check push the next check back', () {
    withSync((async) {
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 8));
      unawaited(sync.syncNow(accountScope()));
      async.flushMicrotasks();
      service.calls.clear();

      async.elapse(const Duration(minutes: 9));
      expect(service.calls, isEmpty);
      async.elapse(const Duration(minutes: 1));

      expect(service.calls, [null]);
    });
  });

  test('opening a contest checked long ago checks it at once', () {
    withSync((async) {
      async.flushMicrotasks();
      sync.focusChanged(_contest.value);
      async.flushMicrotasks();
      sync.focusChanged(null);
      async.elapse(const Duration(minutes: 6));
      service.calls.clear();

      sync.focusChanged(_contest.value);
      async.flushMicrotasks();

      expect(service.calls, [_contest]);
    });
  });

  test('opening a contest just checked does not check again', () {
    withSync((async) {
      async.flushMicrotasks();
      sync.focusChanged(_contest.value);
      async.flushMicrotasks();
      sync.focusChanged(null);
      service.calls.clear();

      sync.focusChanged(_contest.value);
      async.flushMicrotasks();

      expect(service.calls, isEmpty);
    });
  });

  test('a hidden tab asks nothing and an overdue check runs on return', () {
    withSync((async) {
      async.flushMicrotasks();
      service.calls.clear();
      sync.activeChanged(active: false);

      async.elapse(const Duration(hours: 1));
      expect(service.calls, isEmpty);

      sync.activeChanged(active: true);
      async.elapse(Duration.zero);
      expect(service.calls, [null]);
    });
  });

  test('a check brought up while the tab is hidden waits for its return', () {
    withSync((async) {
      async.flushMicrotasks();
      sync.activeChanged(active: false);
      service.calls.clear();

      sync.focusChanged(_contest.value);
      signedIn.set(false);
      signedIn.set(true);
      async.flushMicrotasks();
      expect(service.calls, isEmpty);

      sync.activeChanged(active: true);
      async.flushMicrotasks();
      expect(service.calls, isNotEmpty);
    });
  });

  test('a check under way when the tab is hidden does not start the next', () {
    withSync((async) {
      async.flushMicrotasks();
      service.calls.clear();

      sync.focusChanged(_contest.value);
      sync.activeChanged(active: false);
      async.flushMicrotasks();

      expect(service.calls, [_contest]);
    });
  });

  test('a failed check says why and keeps the pages as they are', () {
    withSync((async) {
      async.flushMicrotasks();
      service.failure = ApiNetworkError(
        'down',
        requestUri: Uri.parse('http://x'),
      );

      unawaited(sync.syncNow(accountScope()));
      async.flushMicrotasks();

      final summary = sync.state.of(accountScope())!;
      expect(summary.problem, SyncProblem.offline);
      expect(summary.dataRevision, 1);
      expect(summary.lastSyncedAt, isNotNull);
    });
  });

  test('a refused sign-in is told apart from a service error', () {
    withSync((async) {
      async.flushMicrotasks();
      service.failure = ApiHttpError(
        'no',
        statusCode: 401,
        body: '',
        requestUri: Uri.parse('http://x'),
      );
      unawaited(sync.syncNow(accountScope()));
      async.flushMicrotasks();
      expect(sync.state.of(accountScope())!.problem, SyncProblem.signInExpired);

      service.failure = ApiHttpError(
        'boom',
        statusCode: 500,
        body: '',
        requestUri: Uri.parse('http://x'),
      );
      unawaited(sync.syncNow(accountScope()));
      async.flushMicrotasks();
      expect(sync.state.of(accountScope())!.problem, SyncProblem.serverError);
    });
  });

  test(
    'the Refresh scope exists before the first check and after it failed',
    () {
      withSync(startSignedIn: false, (async) {
        service.failure = ApiNetworkError(
          'down',
          requestUri: Uri.parse('http://x'),
        );

        signedIn.set(true);
        expect(sync.accountScope, isNotNull);
        async.flushMicrotasks();

        expect(sync.state.of(accountScope())!.problem, SyncProblem.offline);

        service.failure = null;
        unawaited(sync.syncNow(accountScope()));
        async.flushMicrotasks();

        expect(sync.state.of(accountScope())!.problem, isNull);
        expect(revisionOf(accountScope()), 1);
      });
    },
  );

  test('opening a contest during another check still checks it', () {
    withSync(startSignedIn: false, (async) {
      signedIn.set(true);
      // The director's check is still under way.
      sync.focusChanged(_contest.value);
      async.flushMicrotasks();

      expect(service.calls, [null, _contest]);
      expect(revisionOf(contestScope), 1);
    });
  });

  test('a write between loading a page and its first check is not lost', () {
    withSync((async) {
      async.flushMicrotasks();
      service.sequences[_contest] = 5;

      sync.focusChanged(_contest.value);
      async.flushMicrotasks();

      expect(revisionOf(contestScope), 1);
    });
  });

  test('signing out forgets everything and stops the checks', () {
    withSync((async) {
      async.flushMicrotasks();
      signedIn.set(false);
      service.calls.clear();

      async.elapse(const Duration(hours: 1));

      expect(sync.accountScope, isNull);
      expect(sync.state.scopes, isEmpty);
      expect(service.calls, isEmpty);
    });
  });
}
