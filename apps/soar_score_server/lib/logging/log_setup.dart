import 'dart:convert';

import 'package:logging/logging.dart';

import '../config/log_format.dart';

/// Formats [record] as one JSON object (no trailing newline).
String formatJsonRecord(LogRecord record) => jsonEncode({
  'time': record.time.toUtc().toIso8601String(),
  'level': record.level.name,
  'logger': record.loggerName,
  'message': record.message,
  if (record.error != null) 'error': '${record.error}',
  if (record.stackTrace != null) 'stack': '${record.stackTrace}',
});

/// Formats [record] as a readable line.
String formatTextRecord(LogRecord record) {
  final buffer = StringBuffer(
    '${record.time.toUtc().toIso8601String()} ${record.level.name} '
    '${record.loggerName}: ${record.message}',
  );
  if (record.error != null) buffer.write('\n${record.error}');
  if (record.stackTrace != null) buffer.write('\n${record.stackTrace}');
  return buffer.toString();
}

/// Sends every record at or above [level] to [sink] in [format].
///
/// Returns a function that stops logging. [sink] defaults to `print`.
void Function() configureLogging({
  required Level level,
  required LogFormat format,
  void Function(String line)? sink,
}) {
  hierarchicalLoggingEnabled = false;
  Logger.root.level = level;
  final write = sink ?? print;
  final format0 = format == LogFormat.json
      ? formatJsonRecord
      : formatTextRecord;
  final subscription = Logger.root.onRecord.listen(
    (record) => write(format0(record)),
  );
  return subscription.cancel;
}
