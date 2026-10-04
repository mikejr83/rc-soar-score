import 'dart:convert';

import 'example_row.dart';

final RegExp _heading = RegExp(r'^## (.+?)\s*$');

/// Extracts the example rows from one Markdown file.
///
/// Each fenced `json` block belongs to the nearest `##` heading above it. A
/// block holding an object is one row; a block holding an array is one row per
/// element. Headings without a block (such as a results table) yield nothing.
/// Throws [FormatException] for a block that is not valid JSON, sits under no
/// heading, or holds anything other than objects.
List<ExampleRow> parseExampleRows(String markdown, {required String file}) {
  final rows = <ExampleRow>[];
  final counts = <String, int>{};
  String? entity;
  StringBuffer? block;

  for (final line in const LineSplitter().convert(markdown)) {
    if (block == null) {
      final heading = _heading.firstMatch(line);
      if (heading != null) {
        entity = heading.group(1);
      } else if (line.trim() == '```json') {
        if (entity == null) {
          throw FormatException('json block before any heading in $file');
        }
        block = StringBuffer();
      }
      continue;
    }
    if (line.trim() == '```') {
      final decoded = jsonDecode(block.toString());
      final items = decoded is List ? decoded : [decoded];
      for (final item in items) {
        if (item is! Map<String, Object?>) {
          throw FormatException('$entity in $file holds a non-object row');
        }
        final index = counts.update(entity!, (n) => n + 1, ifAbsent: () => 1);
        rows.add(
          ExampleRow(entity: entity, file: file, index: index - 1, json: item),
        );
      }
      block = null;
    } else {
      block.writeln(line);
    }
  }
  if (block != null) {
    throw FormatException('unterminated json block in $file');
  }
  return rows;
}
