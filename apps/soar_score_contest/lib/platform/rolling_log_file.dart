import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:soar_score_core/soar_score_core.dart';

/// The app log as a file that rolls when it grows past [maxBytes].
///
/// The current file is `<name>.log`; rolling renames it to `<name>.1.log`,
/// pushing older ones to `.2` and `.3` and deleting the oldest, so at most
/// [retainedFiles] rolled files are kept besides the current one (like
/// Serilog's or NLog's file targets). Writing never throws: a log that cannot
/// be written must not break the app.
class RollingLogFile {
  RollingLogFile(
    this.directory, {
    this.name = 'soar-score',
    this.maxBytes = defaultMaxBytes,
    this.retainedFiles = defaultRetainedFiles,
  }) {
    try {
      directory.createSync(recursive: true);
      final current = _file(0);
      _size = current.existsSync() ? current.lengthSync() : 0;
    } on FileSystemException {
      _size = 0;
    }
  }

  static const defaultMaxBytes = 300 * 1024;
  static const defaultRetainedFiles = 3;

  final Directory directory;
  final String name;
  final int maxBytes;
  final int retainedFiles;

  int _size = 0;

  File _file(int index) => File(
    p.join(directory.path, index == 0 ? '$name.log' : '$name.$index.log'),
  );

  /// Appends [line] and a newline, rolling first when it would not fit.
  void write(String line) {
    try {
      final text = '$line\n';
      final bytes = text.length;
      if (_size > 0 && _size + bytes > maxBytes) _roll();
      _file(0).writeAsStringSync(text, mode: FileMode.append);
      _size += bytes;
    } on FileSystemException {
      // Dropped: see the class comment.
    }
  }

  void _roll() {
    try {
      final oldest = _file(retainedFiles);
      if (oldest.existsSync()) oldest.deleteSync();
      for (var i = retainedFiles - 1; i >= 0; i--) {
        final file = _file(i);
        if (file.existsSync()) file.renameSync(_file(i + 1).path);
      }
    } on FileSystemException {
      // A file that cannot be moved is overwritten by the next write.
    }
    _size = 0;
  }

  /// The existing log files, oldest first.
  List<File> files() => [
    for (var i = retainedFiles; i >= 0; i--)
      if (_file(i).existsSync()) _file(i),
  ];

  /// All kept text, oldest first.
  String readAll() {
    final buffer = StringBuffer();
    for (final file in files()) {
      try {
        buffer.write(file.readAsStringSync());
      } on FileSystemException {
        // Skipped: a file that cannot be read is not in the export.
      }
    }
    return buffer.toString();
  }

  /// Writes every record on [Logger.root] to this file until the returned
  /// function is called.
  void Function() attach() {
    final subscription = Logger.root.onRecord.listen(
      (record) => write(formatTextRecord(record)),
    );
    return () => unawaited(subscription.cancel());
  }
}
