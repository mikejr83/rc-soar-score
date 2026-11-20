import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:soar_score_contest/platform/app_log.dart';

void main() {
  late Directory dir;
  late AppLog log;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('app_log');
    Logger.root.level = Level.ALL;
  });
  tearDown(() async {
    await log.close();
    dir.deleteSync(recursive: true);
  });

  Future<List<String>> names() async => [
    for (final f in await log.files()) f.uri.pathSegments.last,
  ];

  test('writes the records of the logger to the file', () async {
    log = AppLog(dir)..attach();
    Logger('Test').info('hello log');

    expect(await log.readAll(), contains('INFO Test: hello log'));
    expect(await names(), ['soar-score.log']);
  });

  test('stops writing when closed', () async {
    log = AppLog(dir)..attach();
    Logger('Test').info('before');
    await log.close();
    Logger('Test').info('after');

    expect(await log.readAll(), contains('before'));
    expect(await log.readAll(), isNot(contains('after')));
  });

  test('rolls past the size and keeps three files in all', () async {
    log = AppLog(dir, maxBytes: 400, checkInterval: Duration.zero)..attach();
    final logger = Logger('Test');
    for (var i = 1; i <= 12; i++) {
      logger.info('line-$i ${'x' * 150}');
      // The size is checked and the file rolled between lines.
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    final kept = await names();
    expect(kept.length, lessThanOrEqualTo(AppLog.defaultKeptFiles));
    expect(kept.last, 'soar-score.log');
    expect(kept.length, greaterThan(1));
    final text = await log.readAll();
    expect(text, contains('line-12 '));
    expect(text, isNot(contains('line-1 ')));
  });

  test('summaries name each file with its size', () async {
    log = AppLog(dir)..attach();
    Logger('Test').info('one line');

    final summaries = await log.summaries();
    expect(summaries.single.name, 'soar-score.log');
    expect(summaries.single.bytes, greaterThan(0));
  });
}
