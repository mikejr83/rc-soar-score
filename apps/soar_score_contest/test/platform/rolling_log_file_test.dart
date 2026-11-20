import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:soar_score_contest/platform/rolling_log_file.dart';

void main() {
  late Directory dir;

  final opened = <RollingLogFile>[];

  setUp(() => dir = Directory.systemTemp.createTempSync('rolling_log'));
  tearDown(() {
    // An open file blocks deleting its folder on Windows.
    for (final log in opened) {
      log.close();
    }
    opened.clear();
    dir.deleteSync(recursive: true);
  });

  RollingLogFile open({int maxBytes = RollingLogFile.defaultMaxBytes}) {
    final log = RollingLogFile(dir, maxBytes: maxBytes);
    opened.add(log);
    return log;
  }

  List<String> names(RollingLogFile log) => [
    for (final f in log.files()) f.uri.pathSegments.last,
  ];

  test('appends lines to the current file', () {
    final log = open()
      ..write('one')
      ..write('two');

    expect(names(log), ['soar-score.log']);
    expect(log.readAll(), 'one\ntwo\n');
  });

  test('rolls past the size and keeps the current file and three more', () {
    final log = open(maxBytes: 20);
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

  test('counts bytes, not characters, towards the size', () {
    final log = open(maxBytes: 30);
    log.write('éééééééééé'); // 10 characters, 20 bytes, 21 with the newline
    log.write('éééééééééé');

    expect(names(log), ['soar-score.1.log', 'soar-score.log']);
  });

  test('summaries name each file with its size, oldest first', () {
    final log = open(maxBytes: 20)
      ..write('line-1-xxxxxxxxxx')
      ..write('line-2-xxxxxxxxxx');

    expect(log.summaries(), [
      (name: 'soar-score.1.log', bytes: 18),
      (name: 'soar-score.log', bytes: 18),
    ]);
  });

  test('keeps writing after a restart and reads the size of the file', () {
    (open(maxBytes: 30)..write('first-line')).close();
    final again = open(maxBytes: 30)
      ..write('second-line')
      ..write('third-line');

    expect(names(again), ['soar-score.1.log', 'soar-score.log']);
    expect(again.readAll(), 'first-line\nsecond-line\nthird-line\n');
  });

  test('writing into a missing folder does not throw', () {
    final log = open();
    dir.deleteSync(recursive: true);
    expect(() => log.write('lost'), returnsNormally);
    dir.createSync();
  });

  test('attach writes the records of the logger until stopped', () async {
    final log = open();
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
