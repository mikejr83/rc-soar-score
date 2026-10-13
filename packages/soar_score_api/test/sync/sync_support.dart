import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

final contestId = Id.parse('019c0000-0000-7000-8000-000000000020');
final installationId = Id.parse('019c0000-0000-7000-8000-000000000070');
final mutationId = Id.parse('019c0000-0000-7000-8000-000000000071');
final entityId = Id.parse('019c0000-0000-7000-8000-000000000072');
final accountId = Id.parse('019c0000-0000-7000-8000-000000000050');

SyncMutationDto sampleMutation({Id? dependsOn}) => SyncMutationDto(
  id: mutationId,
  clientMutationId: 'm-1',
  entityType: 'official_score',
  entityId: entityId,
  baseRevision: 3,
  authority: Authority.director,
  clientTime: DateTime.utc(2026, 10, 13, 12),
  dependsOnMutationId: dependsOn,
  payload: const {'time_flown': 540},
);

SyncExchangeRequest sampleRequest({
  List<SyncMutationDto> mutations = const [],
  String? pageToken,
}) => SyncExchangeRequest(
  protocolVersion: SyncProtocol.protocolVersion,
  schemaVersion: 1,
  installationId: installationId,
  scope: SyncScopeDto.contest(contestId),
  lastAcknowledgedSequence: 41,
  pageToken: pageToken,
  mutations: mutations,
);
