import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'sync_mutation_dto.dart';
import 'sync_scope_dto.dart';

part 'sync_exchange_request.g.dart';

/// Body of `POST /api/v1/sync/exchange`: pushes unsent mutations and pulls
/// the changes after the cursor for one scope.
///
/// [mutations] are in dependency order and may be empty (a pull only).
/// [pageToken] is set only to continue a paged pull, with empty [mutations].
@JsonSerializable(
  checked: true,
  explicitToJson: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class SyncExchangeRequest {
  const SyncExchangeRequest({
    required this.protocolVersion,
    required this.schemaVersion,
    required this.installationId,
    required this.scope,
    required this.lastAcknowledgedSequence,
    this.pageToken,
    this.mutations = const [],
  });

  factory SyncExchangeRequest.fromJson(Map<String, dynamic> json) =>
      _$SyncExchangeRequestFromJson(json);

  final int protocolVersion;
  final int schemaVersion;
  final Id installationId;
  final SyncScopeDto scope;
  final int lastAcknowledgedSequence;
  final String? pageToken;
  final List<SyncMutationDto> mutations;

  Map<String, dynamic> toJson() => _$SyncExchangeRequestToJson(this);
}
