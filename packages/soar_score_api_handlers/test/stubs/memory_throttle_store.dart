import 'package:soar_score_core/soar_score_core.dart' as core;

/// A throttle store in memory that several throttles can share, standing in
/// for the service database, with a switch to make it fail.
class MemoryThrottleStore implements core.RequestThrottleStore {
  MemoryThrottleStore({required this.clock});

  final DateTime Function() clock;
  final _rows = <String, ({DateTime start, int count})>{};
  bool failing = false;
  int purges = 0;

  int get rows => _rows.length;

  void _check() {
    if (failing) throw StateError('store down (secret detail)');
  }

  @override
  Future<core.ThrottleCount> hit(
    String bucket,
    String caller, {
    required Duration window,
    DateTime? now,
  }) async {
    _check();
    final at = now ?? clock();
    final key = '$bucket|$caller';
    final row = _rows[key];
    final next = row == null || !at.isBefore(row.start.add(window))
        ? (start: at, count: 1)
        : (start: row.start, count: row.count + 1);
    _rows[key] = next;
    return core.ThrottleCount(count: next.count, windowStart: next.start);
  }

  @override
  Future<core.ThrottleCount?> read(
    String bucket,
    String caller, {
    required Duration window,
    DateTime? now,
  }) async {
    _check();
    final at = now ?? clock();
    final row = _rows['$bucket|$caller'];
    if (row == null || !at.isBefore(row.start.add(window))) return null;
    return core.ThrottleCount(count: row.count, windowStart: row.start);
  }

  @override
  Future<void> purgeBefore(DateTime cutoff) async {
    _check();
    purges++;
    _rows.removeWhere((_, row) => row.start.isBefore(cutoff));
  }
}
