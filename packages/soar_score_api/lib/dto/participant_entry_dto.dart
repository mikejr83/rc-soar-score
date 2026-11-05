import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'participant_overview_dto.dart';

part 'participant_entry_dto.g.dart';

/// One field of the score entry form, from the discipline's scoring schema.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class ScoreFieldDto {
  const ScoreFieldDto({
    required this.key,
    required this.type,
    required this.required,
    this.min,
    this.max,
  });

  factory ScoreFieldDto.fromJson(Map<String, dynamic> json) =>
      _$ScoreFieldDtoFromJson(json);

  /// The component key sent back in a submission, for example `time_flown`.
  final String key;

  /// `seconds`, `integer`, `landing` or `boolean`.
  final String type;
  final bool required;
  final num? min;
  final num? max;

  Map<String, dynamic> toJson() => _$ScoreFieldDtoToJson(this);
}

/// One result from the contest's landing table.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class LandingOptionDto {
  const LandingOptionDto({
    required this.id,
    required this.label,
    required this.points,
    this.description,
  });

  factory LandingOptionDto.fromJson(Map<String, dynamic> json) =>
      _$LandingOptionDtoFromJson(json);

  final String id;
  final String label;
  final int points;
  final String? description;

  Map<String, dynamic> toJson() => _$LandingOptionDtoToJson(this);
}

/// The answer to
/// `GET /api/v1/self-scoring/rounds/{round}/entry`: what the entry form
/// needs for one flight.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class ParticipantEntryContextDto {
  const ParticipantEntryContextDto({
    required this.assignmentId,
    required this.round,
    required this.roundCount,
    required this.group,
    required this.lane,
    required this.matrixRevision,
    required this.scoreRevision,
    required this.rulesVersion,
    required this.state,
    required this.fields,
    required this.landingTable,
    this.allowsMotorRestart = true,
  });

  factory ParticipantEntryContextDto.fromJson(Map<String, dynamic> json) =>
      _$ParticipantEntryContextDtoFromJson(json);

  final Id assignmentId;
  final int round;
  final int roundCount;
  final String group;
  final int lane;
  final int matrixRevision;
  final int scoreRevision;

  /// The discipline-rules version the fields and ranges belong to.
  final String rulesVersion;
  final ParticipantScoreState state;

  /// The fields the pilot may enter. The server rejects any other key and
  /// never offers the cumulative penalty.
  final List<ScoreFieldDto> fields;
  final List<LandingOptionDto> landingTable;
  final bool allowsMotorRestart;

  Map<String, dynamic> toJson() => _$ParticipantEntryContextDtoToJson(this);
}
