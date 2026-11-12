import 'package:drift/drift.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import '../schema/table_group.dart';
import '../sync/sql_placeholders.dart';

/// Request throttle counters in the service database (`request_throttles`),
/// shared by every server instance and kept across restarts.
///
/// A hit is one atomic upsert, so concurrent requests on several machines all
/// count. Backend only: an installation has no such table.
class RequestThrottleStore implements core.RequestThrottleStore {
  RequestThrottleStore(this._db) {
    if (!_db.profile.groups.contains(TableGroup.backendOnly)) {
      throw core.BackendOnlyError('RequestThrottle');
    }
  }

  final SoarScoreDatabase _db;

  @override
  Future<core.ThrottleCount> hit(
    String bucket,
    String caller, {
    required Duration window,
    DateTime? now,
  }) async {
    final at = (now ?? DateTime.now()).toUtc();
    final started = _iso(at);
    final over = _iso(at.subtract(window));
    final rows = await _db
        .customSelect(
          portableSql(
            _db,
            'INSERT INTO request_throttles (bucket, caller, window_start, count) '
            'VALUES (?, ?, ?, 1) '
            'ON CONFLICT (bucket, caller) DO UPDATE SET '
            'count = CASE WHEN request_throttles.window_start <= ? '
            'THEN 1 ELSE request_throttles.count + 1 END, '
            'window_start = CASE WHEN request_throttles.window_start <= ? '
            'THEN excluded.window_start ELSE request_throttles.window_start END '
            'RETURNING count, window_start',
          ),
          variables: [
            Variable<String>(bucket),
            Variable<String>(caller),
            Variable<String>(started),
            Variable<String>(over),
            Variable<String>(over),
          ],
        )
        .get();
    return _count(rows.single);
  }

  @override
  Future<core.ThrottleCount?> read(
    String bucket,
    String caller, {
    required Duration window,
    DateTime? now,
  }) async {
    final over = _iso((now ?? DateTime.now()).toUtc().subtract(window));
    final rows = await _db
        .customSelect(
          portableSql(
            _db,
            'SELECT count, window_start FROM request_throttles '
            'WHERE bucket = ? AND caller = ? AND window_start > ?',
          ),
          variables: [
            Variable<String>(bucket),
            Variable<String>(caller),
            Variable<String>(over),
          ],
        )
        .get();
    return rows.isEmpty ? null : _count(rows.single);
  }

  @override
  Future<void> purgeBefore(DateTime cutoff) => _db.customStatement(
    portableSql(_db, 'DELETE FROM request_throttles WHERE window_start < ?'),
    [_iso(cutoff.toUtc())],
  );

  core.ThrottleCount _count(QueryRow row) => core.ThrottleCount(
    count: row.read<int>('count'),
    windowStart: DateTime.parse(row.read<String>('window_start')),
  );

  /// Fixed-width UTC text (whole milliseconds), so text order is time order.
  static String _iso(DateTime utc) => DateTime.fromMillisecondsSinceEpoch(
    utc.millisecondsSinceEpoch,
    isUtc: true,
  ).toIso8601String();
}
