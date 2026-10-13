import 'dart:io';

import 'package:soar_score_core/soar_score_core.dart';

/// Keeps this installation's identifier in a small file beside the database.
///
/// The identifier is generated on first use and never changes, so the service
/// recognizes the same installation after a restart. The file lives with the
/// database: deleting the database to start over deletes the identity too.
class InstallationIdFile {
  const InstallationIdFile(this.file);

  /// The file for the database at [databasePath].
  factory InstallationIdFile.besides(String databasePath) =>
      InstallationIdFile(File('$databasePath.installation-id'));

  final File file;

  /// The stored identifier, creating and storing one when there is none.
  Future<Id> readOrCreate() async {
    if (await file.exists()) {
      final text = (await file.readAsString()).trim();
      try {
        return Id.parse(text);
      } on FormatException {
        // A damaged file is replaced; the service has not seen this id sync.
      } on ArgumentError {
        // Same as above.
      }
    }
    final id = Id.create();
    await file.writeAsString(id.value, flush: true);
    return id;
  }
}
