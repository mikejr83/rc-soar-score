import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:soar_score_core/config/log_format.dart';
import 'package:soar_score_core/logging/log_setup.dart';
import 'package:test/test.dart';

void main() {
  final record = LogRecord(Level.WARNING, 'hello', 'Thing', StateError('bad'));

  test('JSON records are one parseable line with the error', () {
    final line = formatJsonRecord(record);
    expect(line, isNot(contains('\n')));
    final json = jsonDecode(line) as Map<String, Object?>;
    expect(json['level'], 'WARNING');
    expect(json['logger'], 'Thing');
    expect(json['message'], 'hello');
    expect(json['error'], contains('bad'));
  });

  test('text records are readable', () {
    final line = formatTextRecord(record);
    expect(line, contains('WARNING Thing: hello'));
  });

  test('configureLogging filters by level and can be stopped', () {
    final lines = <String>[];
    final stop = configureLogging(
      level: Level.INFO,
      format: LogFormat.text,
      sink: lines.add,
    );
    final logger = Logger('LogSetupTest');
    logger.fine('hidden');
    logger.info('shown');
    stop();
    logger.info('after stop');

    expect(lines, hasLength(1));
    expect(lines.single, contains('shown'));
  });
}
