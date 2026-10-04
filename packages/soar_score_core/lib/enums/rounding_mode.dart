import 'package:json_annotation/json_annotation.dart';

/// How the final group score is rounded (`rounding_mode` option).
///
/// [json] is the exact text in `plan/data-model/contest-options.md`.
@JsonEnum(valueField: 'json')
enum RoundingMode {
  round('Round'),
  truncate('Truncate');

  const RoundingMode(this.json);

  final String json;
}
