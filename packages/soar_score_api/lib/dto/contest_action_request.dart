import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'contest_action_request.g.dart';

/// Body of `POST /api/v1/contests/{id}/actions`.
@JsonSerializable(checked: true, fieldRename: FieldRename.snake)
class ContestActionRequest {
  const ContestActionRequest({
    required this.action,
    required this.baseRevision,
  });

  factory ContestActionRequest.fromJson(Map<String, dynamic> json) =>
      _$ContestActionRequestFromJson(json);

  final ContestAction action;

  /// The contest revision the caller read; a different stored revision is
  /// answered with 409.
  final int baseRevision;

  Map<String, dynamic> toJson() => _$ContestActionRequestToJson(this);
}
