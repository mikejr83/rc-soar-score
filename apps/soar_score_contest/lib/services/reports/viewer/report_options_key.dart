import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

/// The report viewer's options, remembered per account and shared by every
/// contest: `{ report kind: { option key: value } }`, for example
/// `{"matrix": {"cmp": "1", "paper": "a4"}}`.
///
/// The values are strings, as the viewer already speaks them: booleans as
/// `'1'`/`'0'`, choices by key, and the pages to print as typed. A value the
/// option parsers do not recognise falls back to its default, so a stale or
/// foreign value never crashes the viewer.
final LocalUiKey<Map<String, Map<String, String>>> reportOptionsKey = LocalUiKey(
  name: 'report_options',
  defaultValue: const <String, Map<String, String>>{},
  encode: (options) => options,
  decode: (data) => _read(data),
);

Map<String, Map<String, String>> _read(Object? data) {
  if (data is! Map) {
    return const {};
  }
  final options = <String, Map<String, String>>{};
  for (final entry in data.entries) {
    if (entry.value is Map && entry.key is String) {
      final values = <String, String>{};
      for (final option in (entry.value as Map).entries) {
        if (option.key is String && option.value is String) {
          values[option.key as String] = option.value as String;
        }
      }
      if (values.isNotEmpty) {
        options[entry.key as String] = values;
      }
    }
  }
  return options;
}
