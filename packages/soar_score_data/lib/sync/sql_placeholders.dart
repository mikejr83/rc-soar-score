import 'package:drift/drift.dart';

/// Rewrites the `?` placeholders of [sql] for the database's dialect.
///
/// SQLite takes `?`; PostgreSQL takes `$1`, `$2`, and so on. Hand-written SQL
/// in this package uses `?` and passes through here, so it reads the same on
/// both backends. A `?` inside a quoted string is not a placeholder.
String portableSql(GeneratedDatabase db, String sql) {
  if (db.executor.dialect != SqlDialect.postgres) return sql;
  final out = StringBuffer();
  var index = 0;
  var quote = false;
  for (final char in sql.split('')) {
    if (char == "'") quote = !quote;
    if (char == '?' && !quote) {
      out.write('\$${++index}');
    } else {
      out.write(char);
    }
  }
  return out.toString();
}
