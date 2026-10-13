import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// The service calls the engine makes.
///
/// [ApiClientSyncGateway] is the real one; tests supply a fake.
abstract interface class SyncGateway {
  Future<SyncInfoDto> syncInfo();

  Future<Installation> registerInstallation(
    RegisterInstallationRequest request,
  );

  Future<SyncExchangeResponse> exchange(SyncExchangeRequest request);

  Future<SystemDataResponse> systemData({
    required int afterSequence,
    String? pageToken,
  });

  Future<SyncMutationResult> resolveConflict(
    Id conflictId,
    ResolveConflictRequest request,
  );
}
