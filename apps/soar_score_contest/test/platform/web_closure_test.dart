import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only the native bootstrap files import the sync engine', () {
    final syncImport = RegExp(
      r'''^(?:import|export)\s+['"](?:package:soar_score_sync|(?:\.\./|\./)*(?:platform/)?native_sync\.dart)''',
    );
    final allowed = {
      'lib/platform/native_sync.dart',
      'lib/platform/native_bootstrap.dart',
    };
    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            !allowed.contains(file.path))
          for (final line in file.readAsLinesSync())
            if (syncImport.hasMatch(line)) '${file.path}: $line',
    ];

    expect(offenders, isEmpty);
  });
}
