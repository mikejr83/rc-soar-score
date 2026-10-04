import 'dart:io';

import 'example_parser.dart';
import 'example_row.dart';

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

  /// Entity names from the catalog tables in `plan/data-model/README.md`.
  List<String> catalogEntities() {
    final row = RegExp(r'^\| ([A-Z][A-Za-z]+) +\| \[entities/');
    return File('${_dataModel.path}/README.md')
        .readAsLinesSync()
        .map((line) => row.firstMatch(line)?.group(1))
        .whereType<String>()
        .toList();
  }

  /// Every example row in `examples/entities/*.md` except the README.
  List<ExampleRow> rows() {
    final files =
        Directory('${_dataModel.path}/examples/entities')
            .listSync()
            .whereType<File>()
            .where(
              (f) => f.path.endsWith('.md') && !f.path.endsWith('README.md'),
            )
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    return [
      for (final file in files)
        ...parseExampleRows(
          file.readAsStringSync(),
          file: file.uri.pathSegments.last,
        ),
    ];
  }
}
