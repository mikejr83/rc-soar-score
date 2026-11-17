/// Builds a CSV document from rows of cells, per RFC 4180: CRLF line breaks,
/// and a cell quoted when it holds a comma, a quote or a line break (quotes
/// doubled). A `null` cell is an empty cell, which is not the same as `0`.
class CsvBuilder {
  const CsvBuilder();

  /// Joins [rows], a header included in the first, into a CSV document.
  String build(List<List<String?>> rows) {
    final buffer = StringBuffer();
    for (final row in rows) {
      for (var i = 0; i < row.length; i++) {
        if (i > 0) {
          buffer.write(',');
        }
        buffer.write(_cell(row[i]));
      }
      buffer.write('\r\n');
    }
    return buffer.toString();
  }

  /// The cell's text, quoted only when a comma, quote or line break in it
  /// would change how the spreadsheet reads it.
  String _cell(String? value) {
    final text = value ?? '';
    if (text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }
}
