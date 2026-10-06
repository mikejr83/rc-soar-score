import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'update_contest_request.g.dart';

/// Body of `PUT /api/v1/contests/{id}`: the full identity, schedule and
/// location of the contest. An omitted or null location field clears it.
///
/// The timezone is fixed at creation and cannot be sent.
/// [baseRevision] is the contest revision the caller read; a different
/// stored revision is answered with 409.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@UtcTimestampConverter()
class UpdateContestRequest {
  const UpdateContestRequest({
    required this.baseRevision,
    required this.name,
    required this.startDateTime,
    required this.endDateTime,
    this.host,
    this.city,
    this.state,
    this.country,
  });

  factory UpdateContestRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateContestRequestFromJson(json);

  final int baseRevision;
  final String name;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? host;
  final String? city;
  final String? state;
  final String? country;

  Map<String, dynamic> toJson() => _$UpdateContestRequestToJson(this);
}
