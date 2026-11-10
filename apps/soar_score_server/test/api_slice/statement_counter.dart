import 'package:drift/drift.dart';

/// Counts the statements a database runs, for the statement-count tests.
///
/// Attach it with `executor.interceptWith(counter)`. A test seeds its data,
/// calls [reset], runs one operation and reads [count]. The count is
/// deterministic, so a test can assert a budget with no timing involved.
class StatementCounter extends QueryInterceptor {
  final List<String> _statements = [];

  /// The statements run since the last [reset].
  int get count => _statements.length;

  /// The text of those statements, for a failure message.
  List<String> get statements => List.unmodifiable(_statements);

  void reset() => _statements.clear();

  /// How many of the statements since the last [reset] read from [table].
  int readsOf(String table) => _statements
      .where((s) => s.trimLeft().toUpperCase().startsWith('SELECT'))
      .where((s) => RegExp('\\b$table\\b').hasMatch(s))
      .length;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _statements.add(statement);
    return super.runSelect(executor, statement, args);
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _statements.add(statement);
    return super.runInsert(executor, statement, args);
  }

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _statements.add(statement);
    return super.runUpdate(executor, statement, args);
  }

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _statements.add(statement);
    return super.runDelete(executor, statement, args);
  }

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _statements.add(statement);
    return super.runCustom(executor, statement, args);
  }

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) {
    _statements.add('BATCH of ${statements.statements.length}');
    return super.runBatched(executor, statements);
  }
}
