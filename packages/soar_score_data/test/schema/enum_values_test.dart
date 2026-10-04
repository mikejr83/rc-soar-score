import 'dart:io';

import 'package:soar_score_data/schema/enum_values.dart';
import 'package:test/test.dart';

/// The `@JsonValue` texts of each enum in `soar_score_core/lib/enums`.
Map<String, List<String>> _coreEnumTexts() {
  var dir = Directory.current.absolute;
  while (!Directory('${dir.path}/packages/soar_score_core/lib/enums')
      .existsSync()) {
    if (dir.parent.path == dir.path) throw StateError('core enums not found');
    dir = dir.parent;
  }
  final enums = Directory('${dir.path}/packages/soar_score_core/lib/enums');
  final name = RegExp(r'^enum (\w+)', multiLine: true);
  final value = RegExp(r"@JsonValue\('([^']*)'\)");
  return {
    for (final file in enums.listSync().whereType<File>())
      if (file.path.endsWith('.dart'))
        for (final text in [file.readAsStringSync()])
          if (name.firstMatch(text) case final m?)
            m[1]!: [for (final v in value.allMatches(text)) v[1]!],
  };
}

void main() {
  final core = _coreEnumTexts();

  group('enum value lists', () {
    for (final entry in enumValueLists.entries) {
      test('${entry.key} matches the core enum', () {
        expect(core, contains(entry.key));
        expect(entry.value, equals(core[entry.key]));
      });
    }
  });
}
