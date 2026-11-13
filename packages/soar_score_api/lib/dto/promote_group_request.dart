import 'package:json_annotation/json_annotation.dart';

part 'promote_group_request.g.dart';

/// Body of
/// `POST /api/v1/contests/{id}/rounds/{roundId}/groups/{group}/scores/official`:
/// the submissions the director saw in one group, to accept as official
/// ("mark all valid rows official").
///
/// Each item names a slot, the submission and the score revision the director
/// saw; no components are taken from the request. At most [maxItems] items,
/// for different slots of the group (an empty list, more, a repeated slot or
/// a slot outside the group is a 400). Live slots of the group that the
/// request does not name are never promoted; the answer lists them as
/// `not_requested`.
@JsonSerializable(
  checked: true,
  explicitToJson: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class PromoteGroupRequest {
  const PromoteGroupRequest({required this.items});

  factory PromoteGroupRequest.fromJson(Map<String, dynamic> json) =>
      _$PromoteGroupRequestFromJson(json);

  static const int maxItems = 100;

  final List<PromoteGroupItem> items;

  Map<String, dynamic> toJson() => _$PromoteGroupRequestToJson(this);
}

/// One slot of a [PromoteGroupRequest].
///
/// Only the assignment id must be a string for the request to decode. The
/// source id and revision are kept as sent, so a malformed value refuses its
/// own row (see the handler) rather than the whole request.
class PromoteGroupItem {
  const PromoteGroupItem({
    required this.assignmentId,
    required Object? sourceAttemptId,
    required Object? expectedScoreRevision,
  }) : rawSourceAttemptId = sourceAttemptId,
       rawExpectedScoreRevision = expectedScoreRevision;

  factory PromoteGroupItem.fromJson(Map<String, dynamic> json) {
    final assignmentId = json['assignment_id'];
    if (assignmentId is! String) {
      throw ArgumentError('an item needs a string assignment_id');
    }
    return PromoteGroupItem(
      assignmentId: assignmentId,
      sourceAttemptId: json['source_attempt_id'],
      expectedScoreRevision: json['expected_score_revision'],
    );
  }

  final String assignmentId;
  final Object? rawSourceAttemptId;
  final Object? rawExpectedScoreRevision;

  Map<String, dynamic> toJson() => {
    'assignment_id': assignmentId,
    'source_attempt_id': rawSourceAttemptId,
    'expected_score_revision': rawExpectedScoreRevision,
  };
}

/// A JSON whole number as an int; a fraction such as 1.9, which the generated
/// decoder would truncate, or any other type is refused.
int wholeNumber(Object? value) {
  if (value is int) return value;
  if (value is double && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  throw ArgumentError.value(value, 'revision', 'not a whole number');
}
