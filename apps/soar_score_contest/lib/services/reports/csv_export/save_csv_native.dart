import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;

/// The native build asks where to put the file and writes it. Returns the name
/// of the file written, or `null` when the director cancelled.
Future<String?> saveCsvFile(
  String fileName,
  String csv, {
  String extension = 'csv',
}) async {
  // The dialog's filter and the appended extension use the bare extension.
  final ext = extension.replaceFirst(RegExp(r'^\.'), '');
  final location = await getSaveLocation(
    suggestedName: fileName,
    acceptedTypeGroups: [
      XTypeGroup(label: ext.toUpperCase(), extensions: [ext]),
    ],
  );
  if (location == null) {
    return null;
  }
  var path = location.path;
  // Strip trailing dots so "name." does not become "name..csv".
  path = path.replaceAll(RegExp(r'\.+$'), '');
  // The dialog can change the name; keep the selected extension so the file is
  // saved with it.
  final wanted = '.$ext';
  if (p.extension(path).toLowerCase() != wanted) {
    path = '$path$wanted';
  }
  await File(path).writeAsString(csv);
  return p.basename(path);
}
