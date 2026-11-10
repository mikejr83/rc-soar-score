import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

/// Logs how long every database statement takes, without logging any data.
///
/// Attach it with `executor.interceptWith(...)`. Each statement produces one
/// line on the `db.statements` logger such as
/// `select 12.4ms args=2 SELECT * FROM "contests" WHERE "id" = ?`.
///
/// Only the SQL text is logged, never the arguments (they can hold invitation
/// tokens, names and e-mail addresses), only how many there were. Drift sends
/// values as arguments, but literals written into custom SQL are blanked too:
/// quoted strings become `'?'` and the text is cut to [maxSqlLength].
///
/// The time includes the wait for the driver, so a statement queued behind
/// another on the single connection shows the longer time; the time a
/// transaction waits for the connection before it starts is not measured.
class StatementTimingInterceptor extends QueryInterceptor {
  StatementTimingInterceptor({Logger? logger, this.maxSqlLength = 200})
    : _logger = logger ?? Logger('db.statements');

  final Logger _logger;

  /// The longest SQL text written to the log; the rest is cut off.
  final int maxSqlLength;

  /// The SQL as logged: single-quoted literals blanked, whitespace folded,
  /// cut at [maxSqlLength].
  String sanitize(String sql) {
    final blanked = sql
        .replaceAll(RegExp(r"'(?:[^']|'')*'"), "'?'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return blanked.length <= maxSqlLength
        ? blanked
        : '${blanked.substring(0, maxSqlLength)}...';
  }

  Future<T> _timed<T>(
    String kind,
    String statement,
    int argCount,
    Future<T> Function() run,
  ) async {
    final watch = Stopwatch()..start();
    try {
      return await run();
    } finally {
      watch.stop();
      final ms = (watch.elapsedMicroseconds / 1000).toStringAsFixed(1);
      _logger.info('$kind ${ms}ms args=$argCount ${sanitize(statement)}');
    }
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _timed(
    'select',
    statement,
    args.length,
    () => super.runSelect(executor, statement, args),
  );

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _timed(
    'insert',
    statement,
    args.length,
    () => super.runInsert(executor, statement, args),
  );

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _timed(
    'update',
    statement,
    args.length,
    () => super.runUpdate(executor, statement, args),
  );

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _timed(
    'delete',
    statement,
    args.length,
    () => super.runDelete(executor, statement, args),
  );

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _timed(
    'custom',
    statement,
    args.length,
    () => super.runCustom(executor, statement, args),
  );

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) => _timed(
    'batch',
    statements.statements.isEmpty ? '' : statements.statements.first,
    statements.arguments.length,
    () => super.runBatched(executor, statements),
  );
}
