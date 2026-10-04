import 'package:json_annotation/json_annotation.dart';

/// Whether pilots are assigned a lane (`lane_mode` option).
///
/// [json] is the exact text in `plan/data-model/contest-options.md`.
@JsonEnum(valueField: 'json')
enum LaneMode {
  none('None'),
  random('Random');

  const LaneMode(this.json);

  final String json;
}
