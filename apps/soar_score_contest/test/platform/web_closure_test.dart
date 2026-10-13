import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only the native bootstrap files import the sync engine', () {
    final syncImport = RegExp(
      r'''^(?:import|export)\s+['"](?:package:soar_score_sync|(?:\.\./|\./)*(?:platform/)?(?:native_sync|engine_app_sync)\.dart)''',
    );
    final allowed = {
      'lib/platform/engine_app_sync.dart',
      'lib/platform/native_sync.dart',
      'lib/platform/native_bootstrap.dart',
    };
    // Windows lists paths with backslashes.
    String posix(File file) => file.path.replaceAll(r'\', '/');
    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            !allowed.contains(posix(file)))
          for (final line in file.readAsLinesSync())
            if (syncImport.hasMatch(line)) '${posix(file)}: $line',
    ];

    expect(offenders, isEmpty);
  });
}
