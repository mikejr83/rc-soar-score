import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:logging/logging.dart';
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

void main() {
  late List<String> lines;
  late StreamSubscription<LogRecord> sub;
  final logger = Logger('db.statements.test');

  setUp(() {
    lines = [];
    hierarchicalLoggingEnabled = true;
    logger.level = Level.ALL;
    sub = logger.onRecord.listen((r) => lines.add(r.message));
  });
  tearDown(() => sub.cancel());

  QueryExecutor open() => NativeDatabase.memory().interceptWith(
    StatementTimingInterceptor(logger: logger, maxSqlLength: 60),
  );

  test(
    'logs kind, duration and argument count, never argument values',
    () async {
      final executor = open();
      await executor.ensureOpen(_Dummy());
      await executor.runCustom('CREATE TABLE t (a TEXT, b INT)');
      await executor.runInsert('INSERT INTO t VALUES (?, ?)', [
        'https://score.example/invitations/SECRET-TOKEN',
        1,
      ]);
      await executor.runSelect('SELECT * FROM t WHERE a = ?', ['SECRET-TOKEN']);

      expect(lines, hasLength(3));
      expect(lines[1], matches(RegExp(r'^insert \d+\.\dms args=2 INSERT')));
      expect(lines[2], matches(RegExp(r'^select \d+\.\dms args=1 SELECT')));
      expect(lines.join('\n'), isNot(contains('SECRET-TOKEN')));
      expect(lines.join('\n'), isNot(contains('score.example')));
    },
  );

  test('blanks quoted literals and cuts long SQL', () {
    final interceptor = StatementTimingInterceptor(maxSqlLength: 40);
    expect(
      interceptor.sanitize("SELECT 1 WHERE x = 'it''s a secret'"),
      "SELECT 1 WHERE x = '?'",
    );
    expect(interceptor.sanitize('SELECT ${'a' * 100}'), endsWith('...'));
    expect(interceptor.sanitize('SELECT\n  1'), 'SELECT 1');
  });

  test('logs a failing statement too', () async {
    final executor = open();
    await executor.ensureOpen(_Dummy());
    await expectLater(executor.runCustom('NOT SQL'), throwsA(anything));
    expect(lines.single, startsWith('custom '));
  });
}

class _Dummy extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;
  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
