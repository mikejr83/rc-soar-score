import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'sync_gateway.dart';

/// A [SyncGateway] over the shared [ApiClient].
class ApiClientSyncGateway implements SyncGateway {
  const ApiClientSyncGateway(this._client);

  final ApiClient _client;

  @override
  Future<SyncInfoDto> syncInfo() => _client.syncInfo();

  @override
  Future<Installation> registerInstallation(
    RegisterInstallationRequest request,
  ) => _client.registerInstallation(request);

  @override
  Future<SyncExchangeResponse> exchange(SyncExchangeRequest request) =>
      _client.exchange(request);

  @override
  Future<SystemDataResponse> systemData({
    required int afterSequence,
    String? pageToken,
  }) => _client.systemData(afterSequence: afterSequence, pageToken: pageToken);

  @override
  Future<SyncMutationResult> resolveConflict(
    Id conflictId,
    ResolveConflictRequest request,
  ) => _client.resolveConflict(conflictId, request);
}
