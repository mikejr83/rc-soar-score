import 'package:json_annotation/json_annotation.dart';

part 'request_delisting_request.g.dart';

/// Body of `POST /api/v1/contests/{id}/publication/delist-requests`: ask a
/// system administrator to remove the publication from public view.
///
/// [reason] is optional free text for the administrator.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class RequestDelistingRequest {
  const RequestDelistingRequest({this.reason});

  factory RequestDelistingRequest.fromJson(Map<String, dynamic> json) =>
      _$RequestDelistingRequestFromJson(json);

  final String? reason;

  Map<String, dynamic> toJson() => _$RequestDelistingRequestToJson(this);
}
