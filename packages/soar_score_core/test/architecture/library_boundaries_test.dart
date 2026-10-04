import 'dart:io';

import 'package:test/test.dart';

/// `lib/` is pure domain code: it may import only these libraries.
const _allowedImports = {
  'dart:core',
  'dart:convert',
  'dart:math',
  'package:equatable/equatable.dart',
  'package:json_annotation/json_annotation.dart',
  'package:logging/logging.dart',
};

void main() {
  test('lib imports nothing outside the allowed libraries', () {
    final lib = Directory('lib');
    final directive = RegExp(r'''^(?:import|export)\s+['"]([^'"]+)['"]''');
    final offenders = <String>[];
    for (final file in lib.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      for (final line in file.readAsLinesSync()) {
        final uri = directive.firstMatch(line)?.group(1);
        if (uri == null) continue;
        final isRelative = !uri.contains(':');
        final isOwnPackage = uri.startsWith('package:soar_score_core/');
        if (!isRelative && !isOwnPackage && !_allowedImports.contains(uri)) {
          offenders.add('${file.path}: $uri');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('lib does no file or network I/O', () {
    final forbidden = RegExp(r'dart:(io|html|ffi|isolate)');
    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            forbidden.hasMatch(file.readAsStringSync()))
          file.path,
    ];
    expect(offenders, isEmpty);
  });
}
