import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:soar_score_core/soar_score_core.dart';

import 'sync_timer_factory.dart';

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
/// in the background); resuming runs an overdue check at once. Checks never
/// overlap, and each wait varies by up to [jitter] so installations that
/// started together do not ask together.
class SyncPoller {
  SyncPoller({
    required this.onPoll,
    this.landingInterval = const Duration(minutes: 10),
    this.contestInterval = const Duration(minutes: 5),
    this.jitter = 0.1,
    SyncTimerFactory? timerFactory,
    DateTime Function()? now,
    Random? random,
  }) : _timerFactory = timerFactory ?? Timer.new,
       _now = now ?? DateTime.now,
       _random = random ?? Random();

  /// Runs the check for [focus]. A throw is ignored: the next check is one
  /// interval later.
  final Future<void> Function(SyncPollFocus focus) onPoll;

  final Duration landingInterval;
  final Duration contestInterval;

  /// How far a wait may vary, as a fraction of the interval (0.1 is plus or
  /// minus 10 percent). Zero in tests that count on exact times.
  final double jitter;

  final SyncTimerFactory _timerFactory;
  final DateTime Function() _now;
  final Random _random;
  bool _polling = false;

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
    if (jitter > 0 && delay > Duration.zero) {
      final spread = (_random.nextDouble() * 2 - 1) * jitter;
      delay += Duration(microseconds: (delay.inMicroseconds * spread).round());
    }
    _timer = _timerFactory(delay, _fire);
  }

  Future<void> _fire() async {
    _timer = null;
    if (_disposed || !_enabled || _paused || _polling) return;
    _polling = true;
    try {
      await onPoll(_focus);
    } on Object catch (error, stack) {
      // The next check is one interval after this one.
      developer.log(
        'The periodic sync check failed',
        name: 'SyncPoller',
        error: error,
        stackTrace: stack,
      );
    } finally {
      _polling = false;
    }
    // Always schedules the next check, whether or not the poll synced.
    synced();
  }
}
