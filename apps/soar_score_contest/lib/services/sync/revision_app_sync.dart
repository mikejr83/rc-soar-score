import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'app_sync.dart';
import 'app_sync_state.dart';
import 'conflict_answer.dart';
import 'open_conflict.dart';
import 'refused_change.dart';
import 'sync_problem.dart';
import 'sync_scope_summary.dart';

/// Asks the service where a scope's log stands (`GET /sync/revision`).
typedef FetchRevision = Future<SyncRevisionDto> Function({Id? contestId});

/// The refresh of the web build, which has no sync engine: it reads and
/// writes the hosted service directly, so there is nothing to push or pull.
/// What can go stale is a page that is already open, for example when pilots
/// score from their phones while the director sits on the Scoring page.
///
/// It stands in for the engine in the one way the screens care about: it asks
/// the service now and then whether the data of the contest in front (or the
/// director's own data) changed and, when it did, moves that scope's
/// [SyncScopeSummary.dataRevision] so pages wrapped in `ReloadOnSync` reload.
/// A check reads one number, not the data.
///
/// The schedule is the native one (`docs/sync-schedule.md`): [SyncPoller]
/// checks every 5 min in a contest and 10 min outside one, never while the
/// tab is hidden or nobody is signed in, and any check or click pushes the
/// next one back. [syncNow] is the Refresh button: it reloads the pages
/// whether or not the number moved.
class RevisionAppSync implements AppSync {
  RevisionAppSync({
    required this._fetch,
    required this._isSignedIn,
    required this._signInChanges,
    DateTime Function()? now,
    SyncTimerFactory? timerFactory,
    double jitter = 0.1,
    this.requestTimeout = const Duration(seconds: 15),
  }) : _now = now ?? DateTime.now {
    _poller = SyncPoller(
      onPoll: _poll,
      timerFactory: timerFactory,
      now: now,
      jitter: jitter,
    );
    _signInChanges.addListener(_signInChanged);
    _signInChanged();
  }

  /// How long a check waits for the service before it counts as failed, so a
  /// stalled answer never leaves the Refresh entry busy for good.
  final Duration requestTimeout;

  final FetchRevision _fetch;
  final bool Function() _isSignedIn;
  final Listenable _signInChanges;
  final DateTime Function() _now;
  late final SyncPoller _poller;
  final _controller = StreamController<AppSyncState>.broadcast();

  var _scopes = <SyncScopeKey, SyncScopeSummary>{};
  final _sequences = <SyncScopeKey, int>{};
  final _checkedAt = <SyncScopeKey, DateTime>{};
  SyncScopeKey? _accountScope;
  bool _syncing = false;
  bool _hidden = false;
  final _pending = <Id?, bool>{};
  bool _closed = false;
  bool _enabled = false;

  /// Bumped when the director signs out or in, so a check that was running
  /// for the old session is dropped.
  int _session = 0;

  @override
  bool get available => false;

  @override
  bool get refreshable => true;

  @override
  SyncScopeKey? get accountScope => _accountScope;

  @override
  AppSyncState get state =>
      AppSyncState(syncing: _syncing, scopes: Map.of(_scopes));

  @override
  Stream<AppSyncState> get states => _controller.stream;

  /// The director moved to [contestId]'s pages, or out of any contest when it
  /// is null. Opening a contest not checked for a while checks it at once.
  void focusChanged(String? contestId) {
    Id? id;
    if (contestId != null) {
      try {
        id = Id.parse(contestId);
      } on ArgumentError {
        // Not a contest: treat it as outside one.
      }
    }
    _poller.focusChanged(
      id == null ? const SyncPollLanding() : SyncPollContest(id),
    );
    if (id == null || !_isSignedIn()) return;
    final last = _checkedAt[ContestScopeKey(id)];
    final stale =
        last == null || _now().difference(last) >= _poller.contestInterval;
    if (stale) unawaited(_check([id], force: false));
  }

  /// The tab went to the background ([active] false) or came back.
  void activeChanged({required bool active}) {
    _hidden = !active;
    _poller.paused = !active;
    // Checks that came up while the tab was hidden run now.
    if (active) _runPending();
  }

  @override
  Future<void> refresh(SyncScopeKey scope) async {}

  /// The Refresh button: reloads what [scope]'s pages show, whether or not
  /// anything changed.
  @override
  Future<void> syncNow(SyncScopeKey scope) =>
      _check([scope is ContestScopeKey ? scope.contestId : null], force: true);

  Future<void> _poll(SyncPollFocus focus) => _check(
    [if (focus case SyncPollContest(:final contestId)) contestId, null],
    force: false,
    queue: false,
  );

  /// Looks at each of [targets], a contest or null for the director's own
  /// data. With [force] a target moves even when its number did not.
  Future<void> _check(
    List<Id?> targets, {
    required bool force,
    bool queue = true,
  }) async {
    if (_closed || !_isSignedIn()) return;
    // Nothing is asked of the service from a hidden tab, not even a check that
    // focus, sign-in or the queue brings up. One request runs at a time. A
    // check that cannot run now waits and runs when the tab is back or the
    // running check ends; the timer's own check is not kept, since the timer
    // asks again.
    if (_syncing || _hidden) {
      if (queue) {
        for (final target in targets) {
          _pending[target] = (_pending[target] ?? false) || force;
        }
      }
      return;
    }
    final session = _session;
    _syncing = true;
    _emit();
    try {
      for (var i = 0; i < targets.length; i++) {
        if (_hidden) {
          // The tab was hidden while this ran: the rest waits.
          for (final target in targets.skip(i)) {
            _pending[target] = (_pending[target] ?? false) || force;
          }
          break;
        }
        await _checkOne(targets[i], force: force, session: session);
        if (session != _session) return;
      }
    } finally {
      if (session == _session) {
        _syncing = false;
        _poller.synced();
        _emit();
        _runPending();
      }
    }
  }

  void _runPending() {
    if (_pending.isEmpty) return;
    final next = Map.of(_pending);
    _pending.clear();
    for (final force in {false, true}) {
      final targets = [
        for (final e in next.entries)
          if (e.value == force) e.key,
      ];
      if (targets.isNotEmpty) unawaited(_check(targets, force: force));
    }
  }

  Future<void> _checkOne(
    Id? contestId, {
    required bool force,
    required int session,
  }) async {
    final SyncRevisionDto revision;
    try {
      revision = await _fetch(contestId: contestId).timeout(requestTimeout);
    } on TimeoutException {
      return _failed(contestId, SyncProblem.offline, session);
    } on ApiNetworkError {
      return _failed(contestId, SyncProblem.offline, session);
    } on ApiHttpError catch (error) {
      return _failed(
        contestId,
        error.statusCode == 401
            ? SyncProblem.signInExpired
            : SyncProblem.serverError,
        session,
      );
    } on ApiException {
      return _failed(contestId, SyncProblem.serverError, session);
    }
    if (session != _session) return;
    final key = _scopeOf(contestId);
    if (key == null) return;
    final before = _sequences[key];
    _sequences[key] = revision.sequence;
    _checkedAt[key] = _now();
    // The first look at a scope reloads too: the page may have loaded before
    // it, and a write in between would otherwise become the baseline unseen.
    final moved = force || before == null || before != revision.sequence;
    _scopes[key] = _summary(key, bump: moved, problem: null);
  }

  void _failed(Id? contestId, SyncProblem problem, int session) {
    if (session != _session) return;
    final key = _scopeOf(contestId);
    if (key == null) return;
    _scopes[key] = _summary(key, bump: false, problem: problem);
  }

  /// The scope of [contestId], or of the director's own data when null. The
  /// latter is a label that exists from sign-in on, so the Refresh entry is
  /// there before the first check and stays to retry a failed one; the
  /// service is never sent it.
  SyncScopeKey? _scopeOf(Id? contestId) =>
      contestId == null ? _accountScope : ContestScopeKey(contestId);

  SyncScopeSummary _summary(
    SyncScopeKey key, {
    required bool bump,
    required SyncProblem? problem,
  }) {
    final old = _scopes[key];
    return SyncScopeSummary(
      lastSyncedAt: problem == null ? _now() : old?.lastSyncedAt,
      dataRevision: (old?.dataRevision ?? 0) + (bump ? 1 : 0),
      problem: problem,
    );
  }

  void _signInChanged() {
    if (_closed) return;
    final signedIn = _isSignedIn();
    if (signedIn == _enabled) return;
    _enabled = signedIn;
    _session++;
    _poller.enabled = signedIn;
    if (signedIn) {
      _accountScope = DirectorScopeKey(Id.create());
      _emit();
      unawaited(_check(const [null], force: false));
    } else {
      _scopes = {};
      _sequences.clear();
      _checkedAt.clear();
      _accountScope = null;
      _pending.clear();
      _syncing = false;
      _emit();
    }
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(state);
  }

  @override
  Future<List<RefusedChange>> refusedChanges(SyncScopeKey scope) async =>
      const [];

  @override
  Future<List<OpenConflict>> openConflicts(SyncScopeKey scope) async =>
      const [];

  @override
  Future<ConflictAnswer> resolveConflict(
    SyncScopeKey scope,
    OpenConflict conflict,
    ConflictResolutionChoice choice, {
    Map<String, Object?>? payload,
  }) async => const ConflictAnswer.notAccepted(
    'Conflicts are only used in the Windows app.',
  );

  Future<void> close() async {
    _closed = true;
    _signInChanges.removeListener(_signInChanged);
    _poller.dispose();
    await _controller.close();
  }
}
