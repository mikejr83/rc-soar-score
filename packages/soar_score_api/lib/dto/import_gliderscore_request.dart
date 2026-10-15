/// Body of `POST /api/v1/imports/gliderscore`.
///
/// [path] is the location of the user's GliderScore `.mdb` file on the
/// machine the embedded server runs on. [tables] is the set of table names
/// to include; `null` means every table, in database order.
class ImportGliderscoreRequest {
  const ImportGliderscoreRequest({required this.path, this.tables});

  factory ImportGliderscoreRequest.fromJson(Map<String, dynamic> json) {
    final path = json['path'];
    if (path is! String || path.trim().isEmpty) {
      throw ArgumentError.value(path, 'path', 'a .mdb file path is required');
    }
    return ImportGliderscoreRequest(
      path: path,
      tables: _tablesFromJson(json['tables']),
    );
  }

  /// The location of the `.mdb` on the machine being served.
  final String path;

  /// The table names to include, or `null` for all of them.
  final List<String>? tables;

  Map<String, dynamic> toJson() => {
    'path': path,
    if (tables != null) 'tables': tables,
  };

  static List<String>? _tablesFromJson(dynamic raw) {
    if (raw == null) return null;
    final names = <String>[];
    for (final item in raw as List<dynamic>) {
      final name = item as String;
      if (name.trim().isEmpty) {
        throw ArgumentError.value(
          item,
          'tables',
          'table names must not be empty',
        );
      }
      names.add(name);
    }
    return names;
  }
}
