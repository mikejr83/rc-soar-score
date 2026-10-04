import 'package:json_annotation/json_annotation.dart';

/// Where a score review request stands.
///
/// Serializes as the exact text in `plan/data-model/entities/review_request.md`.
enum ReviewRequestState {
  @JsonValue('Submitted')
  submitted,
  @JsonValue('UnderReview')
  underReview,
  @JsonValue('Approved')
  approved,
  @JsonValue('Rejected')
  rejected,
  @JsonValue('Superseded')
  superseded,
}
