/// How log records are written to the console.
enum LogFormat {
  /// One JSON object per line, for log collectors.
  json,

  /// Readable lines for local development.
  text,
}
