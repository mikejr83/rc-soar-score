import 'dart:convert';
import 'dart:io';

import 'example_row.dart';

/// An entity in the data model catalog and the stem of its documents.
///
/// `team` means `entities/team.md` and `examples/entities/team.json`.
class CatalogEntry {
  const CatalogEntry(this.entity, this.stem);

  final String entity;
  final String stem;
}

/// Test-only access to the data model documentation (library code may not do
/// I/O, test code may).
class ExampleFiles {
  ExampleFiles._(this._dataModel);

  final Directory _dataModel;

  /// Locates `plan/data-model` by walking up from the current directory.
  factory ExampleFiles.locate() {
    var dir = Directory.current.absolute;
    while (true) {
      final candidate = Directory('${dir.path}/plan/data-model');
      if (candidate.existsSync()) return ExampleFiles._(candidate);
      final parent = dir.parent;
      if (parent.path == dir.path) {
        throw StateError(
          'plan/data-model not found above ${Directory.current}',
        );
      }
      dir = parent;
    }
  }

  Directory get _examples => Directory('${_dataModel.path}/examples/entities');

  /// Entities from the catalog tables in `plan/data-model/README.md`.
  List<CatalogEntry> catalog() {
    final row = RegExp(r'^\| ([A-Z][A-Za-z]+) +\| \[entities/([a-z_]+)\.md\]');
    return [
      for (final line in File('${_dataModel.path}/README.md').readAsLinesSync())
        if (row.firstMatch(line) case final m?) CatalogEntry(m[1]!, m[2]!),
    ];
  }

  /// Stems of the `*.json` files in the examples folder.
  Set<String> exampleStems() => {
    for (final file in _examples.listSync().whereType<File>())
      if (file.path.endsWith('.json'))
        file.uri.pathSegments.last.replaceAll(RegExp(r'\.json$'), ''),
  };

  /// The rows in `<stem>.json`, which must be a non-empty array of objects.
  List<ExampleRow> rows(CatalogEntry entry) {
    final name = '${entry.stem}.json';
    final decoded = jsonDecode(
      File('${_examples.path}/$name').readAsStringSync(),
    );
    if (decoded is! List || decoded.isEmpty) {
      throw FormatException('$name must be a non-empty array');
    }
    return [
      for (final (i, item) in decoded.indexed)
        ExampleRow(
          entity: entry.entity,
          file: name,
          index: i,
          json: item is Map<String, Object?>
              ? item
              : throw FormatException('$name row $i is not an object'),
        ),
    ];
  }
}
