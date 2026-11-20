import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:soar_score_contest/platform/rolling_log_file.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('rolling_log'));
  tearDown(() => dir.deleteSync(recursive: true));

  List<String> names(RollingLogFile log) => [
    for (final f in log.files()) f.uri.pathSegments.last,
  ];

  test('appends lines to the current file', () {
    final log = RollingLogFile(dir)
      ..write('one')
      ..write('two');

    expect(names(log), ['soar-score.log']);
    expect(log.readAll(), 'one\ntwo\n');
  });

  test('rolls past the size and keeps the current file and three more', () {
    final log = RollingLogFile(dir, maxBytes: 20);
    for (var i = 1; i <= 8; i++) {
      log.write('line-$i-xxxxxxxxxx'); // 18 characters, 19 with the newline
    }

    expect(names(log), [
      'soar-score.3.log',
      'soar-score.2.log',
      'soar-score.1.log',
      'soar-score.log',
    ]);
    // Each file holds one line; the oldest four lines are gone.
    expect(log.readAll(), startsWith('line-5-'));
    expect(log.readAll(), endsWith('line-8-xxxxxxxxxx\n'));
    expect(log.readAll(), isNot(contains('line-4-')));
  });

  test('keeps writing after a restart and reads the size of the file', () {
    RollingLogFile(dir, maxBytes: 30).write('first-line');
    final again = RollingLogFile(dir, maxBytes: 30)
      ..write('second-line')
      ..write('third-line');

    expect(names(again), ['soar-score.1.log', 'soar-score.log']);
    expect(again.readAll(), 'first-line\nsecond-line\nthird-line\n');
  });

  test('writing into a missing folder does not throw', () {
    final log = RollingLogFile(dir);
    dir.deleteSync(recursive: true);
    expect(() => log.write('lost'), returnsNormally);
    dir.createSync();
  });

  test('attach writes the records of the logger until stopped', () async {
    final log = RollingLogFile(dir);
    Logger.root.level = Level.ALL;
    final stop = log.attach();
    Logger('Test').info('hello log');
    await Future<void>.delayed(Duration.zero);
    stop();
    Logger('Test').info('after stop');
    await Future<void>.delayed(Duration.zero);

    expect(log.readAll(), contains('INFO Test: hello log'));
    expect(log.readAll(), isNot(contains('after stop')));
  });
}
