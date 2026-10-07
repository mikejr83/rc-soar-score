import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'late_add_request.g.dart';

/// Body of `POST /api/v1/contests/{id}/matrix/late-adds`.
///
/// The caller generates [id] (a UUIDv7, the new assignment's id), so repeating
/// the request changes nothing more. The pilot [contestParticipationId] flies
/// [group] and [lane] of round [scheduledRoundId]; the flight counts toward
/// [creditedRoundId], the scheduled round when null. [reason] is required.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class LateAddRequest {
  const LateAddRequest({
    required this.id,
    required this.contestParticipationId,
    required this.scheduledRoundId,
    this.creditedRoundId,
    required this.group,
    this.lane,
    required this.reason,
  });

  factory LateAddRequest.fromJson(Map<String, dynamic> json) =>
      _$LateAddRequestFromJson(json);

  final Id id;
  final Id contestParticipationId;
  final Id scheduledRoundId;
  final Id? creditedRoundId;
  final int group;

  /// Required when the contest uses lanes, absent otherwise.
  final int? lane;
  final String reason;

  Map<String, dynamic> toJson() => _$LateAddRequestToJson(this);
}
