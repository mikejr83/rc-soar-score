import 'package:drift/drift.dart';

/// Request throttle counters: one row per bucket and caller, counting
/// the requests in the caller's current window.
///
/// Operational state of the service, not an entity: it never syncs, is never
/// exported and holds no contest data. [caller] is a keyed hash of the caller's
/// address, so a row never holds an address. Rows live one window long;
/// expired rows are deleted as the counters run.
@DataClassName('RequestThrottleData')
class RequestThrottles extends Table {
  /// What is counted, such as `invitation-attempts`.
  TextColumn get bucket => text()();

  /// The caller, as a keyed hash.
  TextColumn get caller => text()();

  /// When the current window began, UTC, ISO 8601 with milliseconds.
  TextColumn get windowStart => text()();

  /// Requests counted in the current window.
  IntColumn get count => integer()();

  @override
  Set<Column> get primaryKey => {bucket, caller};
}
