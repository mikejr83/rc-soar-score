import 'dart:async';

import 'package:soar_score_core/soar_score_core.dart';

import 'sync_engine.dart';
import 'sync_failure_kind.dart';

/// Turns "a local change was committed" into a push.
///
/// A burst of changes to one scope is coalesced into one sync that starts
/// [window] after the first. The scheduler never blocks the caller and a
/// failed sync never undoes the local change. After a server error it tries
/// again with a growing delay; after an offline, token, update or inactive
/// failure it waits for [connectivityRestored] or the next local change.
class SyncScheduler {
  SyncScheduler(
    this._engine, {
    this.window = const Duration(milliseconds: 500),
    this.maxBackoff = const Duration(minutes: 5),
    SyncTimerFactory? timerFactory,
  }) : _timerFactory = timerFactory ?? Timer.new;

  final SyncEngine _engine;

  /// How long a burst of changes is gathered before one sync.
  final Duration window;

  /// The longest wait between retries after a server error.
  final Duration maxBackoff;

  final SyncTimerFactory _timerFactory;
  final _timers = <SyncScopeKey, Timer>{};
  final _failures = <SyncScopeKey, int>{};
  final _known = <SyncScopeKey>{};
  bool _disposed = false;

  /// Call after a local unit of work commits in [scope].
  void notifyLocalChange(SyncScopeKey scope) {
    _known.add(scope);
    _failures.remove(scope);
    _schedule(scope, window);
  }

  /// Call when the device or the service becomes reachable again, or after
  /// the director signs in. Syncs every scope seen so far.
  void connectivityRestored() {
    for (final scope in _known) {
      _failures.remove(scope);
      _schedule(scope, Duration.zero);
    }
  }

  void dispose() {
    _disposed = true;
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  void _schedule(SyncScopeKey scope, Duration delay) {
    if (_disposed) return;
    // A timer already waiting covers this change too.
    if (_timers.containsKey(scope) && delay > Duration.zero) return;
    _timers.remove(scope)?.cancel();
    _timers[scope] = _timerFactory(delay, () => _run(scope));
  }

  Future<void> _run(SyncScopeKey scope) async {
    _timers.remove(scope);
    if (_disposed) return;
    final failure = await _engine.syncScope(scope);
    if (failure == SyncFailureKind.serverError) {
      final attempt = (_failures[scope] ?? 0) + 1;
      _failures[scope] = attempt;
      var delay = window * (1 << attempt.clamp(1, 20));
      if (delay > maxBackoff) delay = maxBackoff;
      _schedule(scope, delay);
    } else {
      _failures.remove(scope);
    }
  }
}
