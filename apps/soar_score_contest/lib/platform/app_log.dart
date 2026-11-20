import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';
import 'package:path/path.dart' as p;
import 'package:soar_score_core/soar_score_core.dart';

/// The app log as a file that rolls at [maxBytes] and keeps [keptFiles]
/// files in all: `<name>.log` and the older `<name>.log.1`, `.2`, ...
///
/// Writing and rolling are done by `logging_appenders`' rotating file
/// appender, which buffers lines and writes them without blocking the caller.
/// The size is checked every [checkInterval], so a file can pass [maxBytes]
/// a little before it rolls.
class AppLog {
  AppLog(
    this.directory, {
    this.name = 'soar-score.log',
    this.maxBytes = defaultMaxBytes,
    this.keptFiles = defaultKeptFiles,
    Duration checkInterval = const Duration(seconds: 5),
  }) {
    directory.createSync(recursive: true);
    _appender = RotatingFileAppender(
      baseFilePath: p.join(directory.path, name),
      rotateAtSizeBytes: maxBytes,
      keepRotateCount: keptFiles,
      rotateCheckInterval: checkInterval,
      formatter: BlockFormatter.formatRecord(formatTextRecord),
    );
  }

  static const defaultMaxBytes = 300 * 1024;
  static const defaultKeptFiles = 3;

  final Directory directory;
  final String name;
  final int maxBytes;
  final int keptFiles;

  late final RotatingFileAppender _appender;

  /// Writes every record of [Logger.root] to the file.
  void attach() => _appender.attachToLogger(Logger.root);

  /// Stops logging and writes what is buffered.
  Future<void> close() => _appender.dispose();

  /// The existing log files, oldest first, after what was logged so far has
  /// had the chance to reach the disk.
  Future<List<File>> files() async {
    // Lines are written through a buffered sink a moment after they are
    // logged; the appender has no public flush.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _appender.getAllLogFiles().reversed.toList();
  }

  /// The name and size of each existing log file, oldest first. A file that
  /// disappears or cannot be read meanwhile is left out.
  Future<List<({String name, int bytes})>> summaries() async => [
    for (final file in await files()) ?_summary(file),
  ];

  ({String name, int bytes})? _summary(File file) {
    try {
      return (name: p.basename(file.path), bytes: file.lengthSync());
    } on FileSystemException {
      return null;
    }
  }

  /// All kept text, oldest first.
  Future<String> readAll() async {
    final buffer = StringBuffer();
    for (final file in await files()) {
      try {
        buffer.write(await file.readAsString());
      } on FileSystemException {
        // Skipped: a file that cannot be read is not in the export.
      }
    }
    return buffer.toString();
  }
}
