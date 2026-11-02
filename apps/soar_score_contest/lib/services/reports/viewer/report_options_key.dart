import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

/// The report viewer's options, remembered per account and shared by every
/// contest: one key per report kind, `{ option key: value }`, for example
/// `report_options.matrix` -> `{"cmp": "1", "paper": "a4"}`.
///
/// The values are strings, as the viewer already speaks them: booleans as
/// `'1'`/`'0'` and choices by key. The pages to print are view-local and are
/// not remembered here. A value the option parsers do not recognise falls
/// back to its default, so a stale or foreign value never crashes the viewer.
///
/// A separate key per kind is deliberate: a write touches only that kind, so
/// one report never drops another's stored options.
LocalUiKey<Map<String, String>> reportOptionsKeyFor(String kindKey) =>
    LocalUiKey(
      name: 'report_options.$kindKey',
      defaultValue: const <String, String>{},
      encode: (options) => options,
      decode: (data) => _read(data),
    );

Map<String, String> _read(Object? data) {
  if (data is! Map) {
    return const {};
  }
  final values = <String, String>{};
  for (final option in data.entries) {
    if (option.key is String && option.value is String) {
      values[option.key as String] = option.value as String;
    }
  }
  return values;
}
