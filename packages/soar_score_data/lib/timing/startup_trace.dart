import 'package:drift/drift.dart';
import 'package:soar_score_core/soar_score_core.dart' show StartupTrace;

/// Logs statements and commits that take [threshold] or longer, and counts
/// the rest; [summary] reports the totals. Never logs argument values.
class StartupTraceInterceptor extends QueryInterceptor {
  StartupTraceInterceptor({this.threshold = const Duration(milliseconds: 25)});

  final Duration threshold;
  int statements = 0;
  int commits = 0;
  int _statementMicros = 0;
  int _commitMicros = 0;

  void summary(String when) => StartupTrace.mark(
    'SQL totals $when: $statements statements, '
    '${(_statementMicros / 1000).round()}ms in statements, '
    '$commits commits, ${(_commitMicros / 1000).round()}ms in commits',
  );

  Future<T> _timed<T>(String kind, String sql, Future<T> Function() run) async {
    final watch = Stopwatch()..start();
    try {
      return await run();
    } finally {
      statements++;
      _statementMicros += watch.elapsedMicroseconds;
      if (watch.elapsed >= threshold) {
        final text = sql.replaceAll(RegExp(r'\s+'), ' ').trim();
        StartupTrace.mark(
          'slow $kind ${watch.elapsedMilliseconds}ms '
          '${text.length > 120 ? '${text.substring(0, 120)}...' : text}',
        );
      }
    }
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor e,
    String s,
    List<Object?> a,
  ) => _timed('select', s, () => super.runSelect(e, s, a));

  @override
  Future<int> runInsert(QueryExecutor e, String s, List<Object?> a) =>
      _timed('insert', s, () => super.runInsert(e, s, a));

  @override
  Future<int> runUpdate(QueryExecutor e, String s, List<Object?> a) =>
      _timed('update', s, () => super.runUpdate(e, s, a));

  @override
  Future<int> runDelete(QueryExecutor e, String s, List<Object?> a) =>
      _timed('delete', s, () => super.runDelete(e, s, a));

  @override
  Future<void> runCustom(QueryExecutor e, String s, List<Object?> a) =>
      _timed('custom', s, () => super.runCustom(e, s, a));

  @override
  Future<void> commitTransaction(TransactionExecutor inner) async {
    final watch = Stopwatch()..start();
    try {
      await super.commitTransaction(inner);
    } finally {
      commits++;
      _commitMicros += watch.elapsedMicroseconds;
      if (watch.elapsed >= threshold) {
        StartupTrace.mark('slow commit ${watch.elapsedMilliseconds}ms');
      }
    }
  }
}
