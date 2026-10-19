import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('l10n_cli'));
  tearDown(() => dir.deleteSync(recursive: true));

  ProcessResult validate(String fileName, String declared) {
    final file = File('${dir.path}/$fileName')
      ..writeAsStringSync('{"@@locale": "$declared"}');
    return Process.runSync('dart', [
      'run',
      'tool/l10n.dart',
      'validate',
      file.path,
    ]);
  }

  test('a file named for one locale and declaring another is rejected', () {
    final result = validate('app_fr_FR.arb', 'de');

    expect(result.exitCode, 1);
    expect(result.stdout, contains('"@@locale" is "de" but the file is for'));
  });

  test('a file whose name and declaration agree passes', () {
    final result = validate('app_fr.arb', 'fr');

    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  });
}
