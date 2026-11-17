import '../file_name.dart';

/// The export file name: `{Report} – {Contest}.{extension}`, made safe for a
/// file system by the shared [FileName] logic the PDF printer uses.
String csvFileName(String reportName, String contestName, {String extension = 'csv'}) =>
    FileName.named('$reportName – $contestName', extension);
