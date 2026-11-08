import 'package:drift/drift.dart';

/// Runs a check before every write statement and before every commit of the
/// database it is attached to (`executor.interceptWith(...)`).
///
/// A check that throws stops the statement, and a transaction whose commit is
/// stopped is rolled back by Drift, so nothing of it is stored. The embedded
/// app uses it to refuse a write whose profile or sign-in changed after the
/// operation that issued it began: the decision is taken at the last moment
/// before the data is stored, not only when the operation started.
///
/// Reads are not intercepted. The callbacks run in the zone of the code that
/// issued the statement, so they can find the operation it belongs to.
class WriteGuardInterceptor extends QueryInterceptor {
  WriteGuardInterceptor({
    required this.beforeWrite,
    required this.beforeCommit,
  });

  /// Called before an insert, update, delete, batch or custom statement.
  final Future<void> Function() beforeWrite;

  /// Called before a transaction commits.
  final Future<void> Function() beforeCommit;

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    await beforeWrite();
    return super.runInsert(executor, statement, args);
  }

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    await beforeWrite();
    return super.runUpdate(executor, statement, args);
  }

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    await beforeWrite();
    return super.runDelete(executor, statement, args);
  }

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    await beforeWrite();
    return super.runCustom(executor, statement, args);
  }

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) async {
    await beforeWrite();
    return super.runBatched(executor, statements);
  }

  @override
  Future<void> commitTransaction(TransactionExecutor inner) async {
    await beforeCommit();
    return super.commitTransaction(inner);
  }
}
