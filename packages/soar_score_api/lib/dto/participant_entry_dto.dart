import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'participant_overview_dto.dart';
import 'participant_submit_dto.dart';

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
    required this.label,
    required this.type,
    required this.required,
    this.unit,
    this.precision,
    this.min,
    this.max,
    this.options = const [],
    this.dependsOn = const {},
  });

  factory ScoreFieldDto.fromJson(Map<String, dynamic> json) =>
      _$ScoreFieldDtoFromJson(json);

  /// The component key sent back in a submission, for example `time_flown`.
  final String key;

  final String label;

  /// `seconds`, `integer`, `landing` or `boolean`.
  final String type;
  final bool required;
  final String? unit;
  final int? precision;
  final num? min;
  final num? max;

  /// Values for enum-like fields, such as landing choices.
  final List<ScoreFieldOptionDto> options;

  /// Conditions supplied by the discipline schema, interpreted by the app
  /// only for presentation. Submission validation remains server-side.
  final Map<String, Object?> dependsOn;

  Map<String, dynamic> toJson() => _$ScoreFieldDtoToJson(this);
}

@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class ScoreFieldOptionDto {
  const ScoreFieldOptionDto({required this.value, required this.label});

  factory ScoreFieldOptionDto.fromJson(Map<String, dynamic> json) =>
      _$ScoreFieldOptionDtoFromJson(json);

  final String value;
  final String label;

  Map<String, dynamic> toJson() => _$ScoreFieldOptionDtoToJson(this);
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
    this.lane,
    this.taskType,
    required this.matrixRevision,
    required this.scoreRevision,
    required this.rulesVersion,
    required this.state,
    required this.fields,
    required this.landingTable,
    this.allowsMotorRestart = true,
    this.submittedScore,
  });

  factory ParticipantEntryContextDto.fromJson(Map<String, dynamic> json) =>
      _$ParticipantEntryContextDtoFromJson(json);

  final Id assignmentId;
  final int round;
  final int roundCount;
  final String group;
  final int? lane;
  final String? taskType;
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

  /// The score the flight already has, so the form can show what was
  /// entered. Null while the flight has no score.
  final ParticipantScoreDto? submittedScore;

  Map<String, dynamic> toJson() => _$ParticipantEntryContextDtoToJson(this);
}
