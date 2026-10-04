/// One example row from `plan/data-model/examples/entities/`.
class ExampleRow {
  const ExampleRow({
    required this.entity,
    required this.file,
    required this.index,
    required this.json,
  });

  /// The entity name from the `## EntityName` heading above the block.
  final String entity;

  /// The Markdown file the row came from.
  final String file;

  /// Zero-based position among the rows under the same heading.
  final int index;

  /// The row exactly as written.
  final Map<String, Object?> json;

  @override
  String toString() => '$entity #$index ($file)';
}
