import 'dart:convert';
import 'dart:io';

/// The JSON blocks of `plan/data-model/examples/disciplines/<name>.md`, by
/// section heading (`DisciplineProfile`, `LandingResult`, and so on).
///
/// A profile section holds one object; every other section holds an array.
Map<String, Object?> disciplineDocument(String name) {
  var dir = Directory.current.absolute;
  while (!Directory('${dir.path}/plan/data-model/examples/disciplines')
      .existsSync()) {
    if (dir.parent.path == dir.path) throw StateError('examples not found');
    dir = dir.parent;
  }
  // A Windows checkout may convert the markdown to CRLF (core.autocrlf).
  final text = File('${dir.path}/plan/data-model/examples/disciplines/$name.md')
      .readAsStringSync()
      .replaceAll('\r\n', '\n');
  final block = RegExp(
    r'^## (\w+)\n(?:(?!^## )[\s\S])*?```json\n([\s\S]*?)\n```',
    multiLine: true,
  );
  return {
    for (final match in block.allMatches(text))
      match[1]!: jsonDecode(match[2]!),
  };
}
