import 'package:json_annotation/json_annotation.dart';

/// How the matrix is drawn (`draw_mode` option).
///
/// [json] is the exact text in `plan/data-model/contest-options.md`.
@JsonEnum(valueField: 'json')
enum DrawMode {
  standardManOnMan('StandardManOnMan'),
  seededManOnMan('SeededManOnMan');

  const DrawMode(this.json);

  final String json;
}
