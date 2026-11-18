import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;

import 'score_export_error.dart';

/// The native build asks where to put the file and writes it. Returns the name
/// of the file written, or `null` when the director cancelled.
Future<String?> saveCsvFile(
  String fileName,
  String csv, {
  String extension = 'csv',
}) async {
  final location = await getSaveLocation(
    suggestedName: fileName,
    acceptedTypeGroups: [
      XTypeGroup(
        label: extension.replaceFirst(RegExp(r'^\.'), '').toUpperCase(),
        extensions: [extension.replaceFirst(RegExp(r'^\.'), '')],
      ),
    ],
  );
  if (location == null) {
    return null;
  }
  // The final path may differ from the one the dialog confirmed (when the
  // director typed a name without the extension); if that would overwrite an
  // existing file, refuse instead of silently truncating it.
  final path = finalSavePath(
    location.path,
    extension,
    exists: (path) => File(path).existsSync(),
  );
  await File(path).writeAsString(csv);
  return p.basename(path);
}

/// The final save path for a path [chosen] in the save dialog, with [ext]
/// applied: the dialog's extension is kept, or it is appended.
///
/// The dialog confirms the overwrite for the name the director typed, not for
/// a path we later adjust. So when appending [ext] would change the target and
/// that target already exists, this throws a [ScoreExportError] rather than
/// silently overwriting the file. [exists] reports whether a path exists and is
/// injected so the logic is testable.
String finalSavePath(
  String chosen,
  String ext, {
  required bool Function(String path) exists,
}) {
  final bare = ext.replaceFirst(RegExp(r'^\.'), '');
  // Strip trailing dots so "name." does not become "name..csv".
  var path = chosen.replaceAll(RegExp(r'\.+$'), '');
  final wanted = '.$bare';
  if (p.extension(path).toLowerCase() == wanted) {
    // The dialog already named the final file; its overwrite check applies.
    return path;
  }
  path = '$path$wanted';
  if (exists(path)) {
    throw ScoreExportError(
      'The file "$path" already exists and would be overwritten. Choose a '
      'different name or location, or pick the existing file to replace it '
      'on purpose.',
    );
  }
  return path;
}
