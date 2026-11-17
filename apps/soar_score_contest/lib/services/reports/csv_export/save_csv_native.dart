import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;

/// The native build asks where to put the CSV and writes it. Returns the name
/// of the file written, or `null` when the director cancelled.
Future<String?> saveCsvFile(String fileName, String csv) async {
  final location = await getSaveLocation(
    suggestedName: fileName,
    acceptedTypeGroups: const [
      XTypeGroup(label: 'CSV', extensions: ['csv']),
    ],
  );
  if (location == null) {
    return null;
  }
  var path = location.path;
  // The dialog can change the name; keep the CSV extension so the file is
  // always a CSV.
  if (!p.extension(path).toLowerCase().endsWith('csv')) {
    path = '$path.csv';
  }
  await File(path).writeAsString(csv);
  return p.basename(path);
}
