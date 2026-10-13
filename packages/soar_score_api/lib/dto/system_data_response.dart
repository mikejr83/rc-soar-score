import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'sync_change_dto.dart';

part 'system_data_response.g.dart';

/// Response of `GET /api/v1/sync/system-data`: pull-only system data after
/// the installation's `system_data_seq`.
@JsonSerializable(
  checked: true,
  explicitToJson: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class SystemDataResponse {
  const SystemDataResponse({
    required this.changes,
    required this.systemDataSeq,
    this.nextPageToken,
  });

  factory SystemDataResponse.fromJson(Map<String, dynamic> json) =>
      _$SystemDataResponseFromJson(json);

  final List<SyncChangeDto> changes;

  /// The highest system-data sequence in [changes], or the request's own
  /// position when nothing is new.
  final int systemDataSeq;

  final String? nextPageToken;

  Map<String, dynamic> toJson() => _$SystemDataResponseToJson(this);
}
