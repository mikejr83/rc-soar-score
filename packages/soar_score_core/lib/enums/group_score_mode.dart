import 'package:json_annotation/json_annotation.dart';

/// How a group score is computed (`group_score_mode` option).
///
/// [json] is the exact text in `plan/data-model/contest-options.md`.
@JsonEnum(valueField: 'json')
enum GroupScoreMode {
  raw('Raw'),
  normalized('Normalized'),
  time('Time');

  const GroupScoreMode(this.json);

  final String json;
}
