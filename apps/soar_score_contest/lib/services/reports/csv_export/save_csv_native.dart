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
  await File(location.path).writeAsString(csv);
  return p.basename(location.path);
}
