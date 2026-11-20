import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:soar_score_core/soar_score_core.dart';

/// The app log as a file that rolls when it grows past [maxBytes].
///
/// The current file is `<name>.log`; rolling renames it to `<name>.1.log`,
/// pushing older ones to `.2` and `.3` and deleting the oldest, so at most
/// [retainedFiles] rolled files are kept besides the current one (like
/// Serilog's or NLog's file targets). The current file stays open between
/// writes and is closed before a roll (a file cannot be renamed while open on
/// Windows). Writing never throws: a log that cannot be written must not break
/// the app.
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
  RandomAccessFile? _open;

  File _file(int index) => File(
    p.join(directory.path, index == 0 ? '$name.log' : '$name.$index.log'),
  );

  /// Appends [line] and a newline, rolling first when it would not fit.
  void write(String line) {
    try {
      final bytes = utf8.encode('$line\n');
      if (_size > 0 && _size + bytes.length > maxBytes) _roll();
      final open = _open ??= _file(0).openSync(mode: FileMode.append);
      open.writeFromSync(bytes);
      _size += bytes.length;
    } on FileSystemException {
      // Dropped: see the class comment. The next write opens the file again.
      close();
    }
  }

  void _roll() {
    close();
    try {
      final oldest = _file(retainedFiles);
      if (oldest.existsSync()) oldest.deleteSync();
      for (var i = retainedFiles - 1; i >= 0; i--) {
        final file = _file(i);
        if (file.existsSync()) file.renameSync(_file(i + 1).path);
      }
    } on FileSystemException {
      // A file that cannot be moved stays where it is and the next write
      // appends to it, so the file grows past the limit until a roll works.
    }
    _size = 0;
  }

  /// Closes the open file. Writing again reopens it.
  void close() {
    try {
      _open?.closeSync();
    } on FileSystemException {
      // Nothing more to release.
    }
    _open = null;
  }

  /// The existing log files, oldest first.
  List<File> files() => [
    for (var i = retainedFiles; i >= 0; i--)
      if (_file(i).existsSync()) _file(i),
  ];

  /// The name and size of each existing log file, oldest first. A file that
  /// disappears or cannot be read meanwhile is left out.
  List<({String name, int bytes})> summaries() => [
    for (final file in files()) ?_summary(file),
  ];

  ({String name, int bytes})? _summary(File file) {
    try {
      return (name: p.basename(file.path), bytes: file.lengthSync());
    } on FileSystemException {
      return null;
    }
  }

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
  /// function is called, which also closes the file.
  void Function() attach() {
    final subscription = Logger.root.onRecord.listen(
      (record) => write(formatTextRecord(record)),
    );
    return () {
      subscription.cancel();
      close();
    };
  }
}
