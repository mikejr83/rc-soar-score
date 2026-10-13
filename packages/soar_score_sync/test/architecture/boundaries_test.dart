import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('pubspec depends only on soar_score_core and soar_score_api', () {
    final lines = File('pubspec.yaml').readAsLinesSync();
    final start = lines.indexOf('dependencies:');
    final end = lines.indexOf('dev_dependencies:');
    final names = [
      for (final line in lines.sublist(start + 1, end))
        if (RegExp(r'^  \w').hasMatch(line)) line.trim().split(':').first,
    ];

    expect(names, unorderedEquals(['soar_score_api', 'soar_score_core']));
  });

  test('lib imports no Flutter, no data layer and no dart:io', () {
    final forbidden = RegExp(
      r'''^(?:import|export)\s+['"](?:dart:(?:io|html|ffi|isolate)|package:flutter|package:drift|package:soar_score_data|package:sqlite3)''',
    );
    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File && file.path.endsWith('.dart'))
          for (final line in file.readAsLinesSync())
            if (forbidden.hasMatch(line)) '${file.path}: $line',
    ];

    expect(offenders, isEmpty);
  });
}
