import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Whether the local application storage can be read, for the status bar's
/// storage indicator.
///
/// [probe] does one small read and throws when the storage cannot be used. The
/// monitor checks at start, every [pollInterval] (never when null) and when the
/// director retries, and keeps when it last got an answer. Checks do not
/// overlap.
class StorageMonitor extends ChangeNotifier {
  StorageMonitor({
    required this.probe,
    Duration? pollInterval = const Duration(seconds: 30),
  }) {
    if (pollInterval != null) {
      _timer = Timer.periodic(pollInterval, (_) => unawaited(retry()));
    }
    unawaited(retry());
  }

  /// Reads something small from the storage; throws when it cannot.
  final Future<void> Function() probe;

  Timer? _timer;
  bool _checking = false;
  bool _disposed = false;

  ConnectivityStatus _status = ConnectivityStatus.checking;
  DateTime? _lastObservedAt;
  String? _lastError;

  /// Checking before the first answer, then available or unavailable.
  ConnectivityStatus get status => _status;

  /// When the storage last answered, successfully or not; null before that.
  DateTime? get lastObservedAt => _lastObservedAt;

  /// Why the last check failed; null when it did not.
  String? get lastError => _lastError;

  /// Checks the storage now. A check already running is not repeated.
  Future<void> retry() async {
    if (_disposed || _checking) return;
    _checking = true;
    final before = _status;
    if (before == ConnectivityStatus.unavailable) {
      _status = ConnectivityStatus.checking;
      notifyListeners();
    }
    try {
      await probe();
      _status = ConnectivityStatus.available;
      _lastError = null;
    } on Object catch (error) {
      _status = ConnectivityStatus.unavailable;
      _lastError = error.toString();
    } finally {
      _checking = false;
    }
    if (_disposed) return;
    _lastObservedAt = DateTime.now();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
