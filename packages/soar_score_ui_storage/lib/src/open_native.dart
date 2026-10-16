import 'dart:io';

import 'package:path/path.dart' as p;

import 'local_ui_backend.dart';
import 'sqlite_local_ui_backend.dart';

/// The SQLite file for UI state inside [directory].
Future<LocalUiBackend> openPlatformBackend({String? directory}) async {
  if (directory == null) {
    throw ArgumentError.notNull('directory');
  }
  await Directory(directory).create(recursive: true);
  return SqliteLocalUiBackend.open(p.join(directory, uiDatabaseName));
}

const String uiDatabaseName = 'soar_score_ui.db';
