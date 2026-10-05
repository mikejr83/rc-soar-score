import 'dart:convert';
import 'dart:io';

/// The documented example rows in `plan/data-model/examples/entities`.
Directory _examples() {
  var dir = Directory.current.absolute;
  while (!Directory('${dir.path}/plan/data-model/examples/entities')
      .existsSync()) {
    if (dir.parent.path == dir.path) throw StateError('examples not found');
    dir = dir.parent;
  }
  return Directory('${dir.path}/plan/data-model/examples/entities');
}

/// The rows of `<file>.json`, as written.
List<Map<String, Object?>> exampleRows(String file) => (jsonDecode(
  File('${_examples().path}/$file.json').readAsStringSync(),
) as List).cast<Map<String, Object?>>();

/// The names (without `.json`) of every example file.
List<String> exampleFileNames() => [
  for (final file in _examples().listSync().whereType<File>())
    if (file.path.endsWith('.json'))
      file.uri.pathSegments.last.replaceAll('.json', ''),
]..sort();
