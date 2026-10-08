import 'package:json_annotation/json_annotation.dart';

part 'publish_contest_request.g.dart';

/// Body of `POST /api/v1/contests/{id}/publication`: publish the contest as
/// it is now.
///
/// The caller generates [clientMutationId], so repeating the request returns
/// the projection it created the first time. [sourceContestRevision] is the
/// contest revision the director reviewed; a contest that has moved on is
/// answered with 409 `stale_source_revision`.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class PublishContestRequest {
  const PublishContestRequest({
    required this.clientMutationId,
    required this.sourceContestRevision,
  });

  factory PublishContestRequest.fromJson(Map<String, dynamic> json) =>
      _$PublishContestRequestFromJson(json);

  final String clientMutationId;
  final int sourceContestRevision;

  Map<String, dynamic> toJson() => _$PublishContestRequestToJson(this);
}
