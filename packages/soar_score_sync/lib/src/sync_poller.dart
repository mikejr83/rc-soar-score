import 'dart:async';

import 'package:soar_score_core/soar_score_core.dart';

import 'sync_scheduler.dart' show SyncTimerFactory;

/// Where the director is, which sets how often the service is asked for
/// changes made elsewhere (participants scoring, another installation).
sealed class SyncPollFocus {
  const SyncPollFocus();
}

/// No contest is selected: the landing page and the Contests pages.
final class SyncPollLanding extends SyncPollFocus {
  const SyncPollLanding();

  @override
  bool operator ==(Object other) => other is SyncPollLanding;

  @override
  int get hashCode => 1;
}

/// A contest is open.
final class SyncPollContest extends SyncPollFocus {
  const SyncPollContest(this.contestId);

  final Id contestId;

  @override
  bool operator ==(Object other) =>
      other is SyncPollContest && other.contestId == contestId;

  @override
  int get hashCode => contestId.hashCode;
}

/// Asks the service for changes now and then while the app is online.
///
/// One timer. It runs [onPoll] one interval after the last sync of any kind
/// ([synced]), so a manual sync or a sync after a local change pushes the next
/// check back. The interval is [landingInterval] outside a contest and
/// [contestInterval] inside one. Nothing runs while [enabled] is false (not
/// signed in, or the service is not reachable) or while [paused] (the app is
/// in the background); resuming runs an overdue check at once.
class SyncPoller {
  SyncPoller({
    required this.onPoll,
    this.landingInterval = const Duration(minutes: 10),
    this.contestInterval = const Duration(minutes: 5),
    SyncTimerFactory? timerFactory,
    DateTime Function()? now,
  }) : _timerFactory = timerFactory ?? Timer.new,
       _now = now ?? DateTime.now;

  /// Runs the check for [focus]. A throw is ignored: the next check is one
  /// interval later.
  final Future<void> Function(SyncPollFocus focus) onPoll;

  final Duration landingInterval;
  final Duration contestInterval;
  final SyncTimerFactory _timerFactory;
  final DateTime Function() _now;

  SyncPollFocus _focus = const SyncPollLanding();
  bool _enabled = false;
  bool _paused = false;
  bool _disposed = false;
  DateTime? _lastSyncAt;
  Timer? _timer;

  SyncPollFocus get focus => _focus;

  Duration get interval => switch (_focus) {
    SyncPollLanding() => landingInterval,
    SyncPollContest() => contestInterval,
  };

  /// Whether checks may run at all.
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    _reschedule();
  }

  /// Whether the app is in the background.
  set paused(bool value) {
    if (_paused == value) return;
    _paused = value;
    _reschedule();
  }

  /// The director moved to [focus].
  void focusChanged(SyncPollFocus focus) {
    if (_focus == focus) return;
    _focus = focus;
    _reschedule();
  }

  /// A sync ended, whoever started it: the next check is one interval later.
  void synced() {
    _lastSyncAt = _now();
    _reschedule();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }

  void _reschedule() {
    _timer?.cancel();
    _timer = null;
    if (_disposed || !_enabled || _paused) return;
    final last = _lastSyncAt;
    var delay = last == null ? interval : interval - _now().difference(last);
    if (delay.isNegative) delay = Duration.zero;
    _timer = _timerFactory(delay, _fire);
  }

  Future<void> _fire() async {
    _timer = null;
    if (_disposed || !_enabled || _paused) return;
    try {
      await onPoll(_focus);
    } on Object {
      // The next check is one interval after this one.
    }
    // The poll normally ends in a sync, which called [synced]; this covers a
    // poll that synced nothing, so the checks never stop.
    if (_timer == null) synced();
  }
}
