import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'create_contest_request.g.dart';

/// Body of `POST /api/v1/contests`.
///
/// The caller generates [id] (a UUIDv7), so repeating the request returns
/// the contest it created instead of creating another.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
@UtcTimestampConverter()
class CreateContestRequest {
  const CreateContestRequest({
    required this.id,
    required this.name,
    required this.startDateTime,
    required this.endDateTime,
    required this.timezone,
    this.host,
    this.city,
    this.state,
    this.country,
  });

  factory CreateContestRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateContestRequestFromJson(json);

  final Id id;
  final String name;
  final DateTime startDateTime;
  final DateTime endDateTime;

  /// IANA timezone name, fixed once the contest is created.
  final String timezone;
  final String? host;
  final String? city;
  final String? state;
  final String? country;

  Map<String, dynamic> toJson() => _$CreateContestRequestToJson(this);
}
