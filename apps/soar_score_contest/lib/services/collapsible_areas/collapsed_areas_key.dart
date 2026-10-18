import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

/// The open or hidden choice for each area the user has changed, by area id.
/// Areas without an entry keep their default. One key for all areas, so
/// registering a new area needs no new storage and a reset is a single remove.
const LocalUiKey<Map<String, bool>> areaChoicesKey = LocalUiKey(
  name: 'area_choices',
  defaultValue: <String, bool>{},
  encode: _encode,
  decode: _decode,
);

Object? _encode(Map<String, bool> choices) => choices;

Map<String, bool> _decode(Object? data) => {
  for (final entry in (data as Map).entries)
    if (entry.value is bool) entry.key as String: entry.value as bool,
};
