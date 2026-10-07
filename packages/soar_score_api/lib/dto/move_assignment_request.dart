import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'move_assignment_request.g.dart';

/// Body of
/// `POST /api/v1/contests/{id}/matrix/assignments/{assignmentId}/moves`.
///
/// The caller generates [id] (a UUIDv7, the new assignment's id), so repeating
/// the request changes nothing more. The pilot moves to [group] and [lane] of
/// [scheduledRoundId], which is the pilot's current round when null. [reason]
/// is required. A move from or into a locked group, or of a locked score,
/// needs [overrideLocks]; the reason then records why.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class MoveAssignmentRequest {
  const MoveAssignmentRequest({
    required this.id,
    this.scheduledRoundId,
    required this.group,
    this.lane,
    required this.reason,
    this.overrideLocks = false,
  });

  factory MoveAssignmentRequest.fromJson(Map<String, dynamic> json) =>
      _$MoveAssignmentRequestFromJson(json);

  final Id id;
  final Id? scheduledRoundId;
  final int group;

  /// Required when the contest uses lanes, absent otherwise.
  final int? lane;
  final String reason;
  final bool overrideLocks;

  Map<String, dynamic> toJson() => _$MoveAssignmentRequestToJson(this);
}
