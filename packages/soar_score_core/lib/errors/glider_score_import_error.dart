/// A GliderScore import failed before or during the transfer.
///
/// The API layer maps each subclass to its HTTP status through
/// [statusCode] and [code]; the wizard shows [message] verbatim.
sealed class GliderScoreImportError extends Error {
  GliderScoreImportError(
    this.message, {
    required this.statusCode,
    required this.code,
  });

  final String message;
  final int statusCode;
  final String code;

  @override
  String toString() => '$runtimeType: $message';
}

/// The helper binaries are not present on this machine.
class ImportUnavailableError extends GliderScoreImportError {
  ImportUnavailableError(super.message)
    : super(statusCode: 503, code: 'import_unavailable');
}

/// The referenced file does not exist.
class ImportDatabaseNotFoundError extends GliderScoreImportError {
  ImportDatabaseNotFoundError(super.message)
    : super(statusCode: 404, code: 'import_not_found');
}

/// The referenced file is not a `.mdb` database.
class ImportUnsupportedFileError extends GliderScoreImportError {
  ImportUnsupportedFileError(super.message)
    : super(statusCode: 415, code: 'import_unsupported');
}

/// The database could not be opened or read by the helper.
class ImportCorruptDatabaseError extends GliderScoreImportError {
  ImportCorruptDatabaseError(super.message)
    : super(statusCode: 422, code: 'import_corrupt');
}

/// A row of the table was not a JSON object.
class ImportMalformedTableError extends GliderScoreImportError {
  ImportMalformedTableError(super.message)
    : super(statusCode: 422, code: 'import_malformed');
}

/// The requested table is not in the database.
class ImportTableMissingError extends GliderScoreImportError {
  ImportTableMissingError(super.message)
    : super(statusCode: 404, code: 'import_table_not_found');
}
