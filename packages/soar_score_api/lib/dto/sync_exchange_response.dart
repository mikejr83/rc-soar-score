import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'sync_change_dto.dart';
import 'sync_conflict_ref.dart';
import 'sync_mutation_result.dart';

part 'sync_exchange_response.g.dart';

/// Response of `POST /api/v1/sync/exchange`.
///
/// [results] has one entry per submitted mutation, in request order.
/// [changes] are the accepted changes after the request's cursor, in
/// sequence order. A non-null [nextPageToken] means more changes remain.
@JsonSerializable(
  checked: true,
  explicitToJson: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class SyncExchangeResponse {
  const SyncExchangeResponse({
    required this.protocolVersion,
    required this.results,
    required this.changes,
    required this.conflicts,
    required this.serverSequence,
    this.nextPageToken,
  });

  factory SyncExchangeResponse.fromJson(Map<String, dynamic> json) =>
      _$SyncExchangeResponseFromJson(json);

  final int protocolVersion;
  final List<SyncMutationResult> results;
  final List<SyncChangeDto> changes;
  final List<SyncConflictRef> conflicts;
  final String? nextPageToken;

  /// The scope's highest sequence when the response was built.
  final int serverSequence;

  Map<String, dynamic> toJson() => _$SyncExchangeResponseToJson(this);
}
