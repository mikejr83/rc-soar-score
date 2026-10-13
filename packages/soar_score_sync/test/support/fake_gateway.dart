import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_sync/soar_score_sync.dart';

/// A scripted [SyncGateway]. Each call is logged, and requests are kept.
class FakeGateway implements SyncGateway {
  FakeGateway(this.log);

  final List<String> log;
  final exchanges = <SyncExchangeRequest>[];
  final resolutions = <ResolveConflictRequest>[];
  final registrations = <RegisterInstallationRequest>[];
  var infoCalls = 0;

  SyncInfoDto info = SyncInfoDto(
    protocolVersion: 1,
    minProtocolVersion: 1,
    minSchemaVersion: 1,
    maxSchemaVersion: 1,
    serverTime: DateTime.utc(2026, 10, 13),
  );

  /// Answers an exchange; throw to simulate a failure.
  Future<SyncExchangeResponse> Function(SyncExchangeRequest request)
  onExchange = (request) async => response();

  Future<SystemDataResponse> Function(int after, String? token) onSystemData = (
    after,
    token,
  ) async => SystemDataResponse(changes: const [], systemDataSeq: after);

  Object? registerError;
  Object? resolveError;

  /// Overrides the answer to a conflict resolution (default: accepted).
  SyncMutationResult? resolveResult;

  @override
  Future<SyncInfoDto> syncInfo() async {
    infoCalls++;
    return info;
  }

  @override
  Future<Installation> registerInstallation(
    RegisterInstallationRequest request,
  ) async {
    log.add('register');
    final error = registerError;
    if (error != null) throw error;
    registrations.add(request);
    return Installation(
      id: request.id,
      ownerAccountId: Id.parse('019c0000-0000-7000-8000-000000000050'),
      label: request.label,
      platform: request.platform,
      createdAt: DateTime.utc(2026, 10, 13),
    );
  }

  @override
  Future<SyncExchangeResponse> exchange(SyncExchangeRequest request) async {
    exchanges.add(request);
    log.add(
      'exchange:${request.mutations.length}'
      '${request.pageToken == null ? '' : ':page'}',
    );
    return onExchange(request);
  }

  @override
  Future<SystemDataResponse> systemData({
    required int afterSequence,
    String? pageToken,
  }) {
    log.add('system:$afterSequence');
    return onSystemData(afterSequence, pageToken);
  }

  @override
  Future<SyncMutationResult> resolveConflict(
    Id conflictId,
    ResolveConflictRequest request,
  ) async {
    log.add('resolve');
    final error = resolveError;
    if (error != null) throw error;
    resolutions.add(request);
    return resolveResult ??
        SyncMutationResult(
          clientMutationId: request.clientMutationId,
          outcome: MutationOutcome.accepted,
          revision: 2,
          sequence: 99,
        );
  }

  static SyncExchangeResponse response({
    List<SyncMutationResult> results = const [],
    List<SyncChangeDto> changes = const [],
    String? nextPageToken,
    int serverSequence = 0,
  }) => SyncExchangeResponse(
    protocolVersion: 1,
    results: results,
    changes: changes,
    conflicts: const [],
    nextPageToken: nextPageToken,
    serverSequence: serverSequence,
  );
}

ApiHttpError httpError(int status, {String code = 'error'}) => ApiHttpError(
  'failed',
  statusCode: status,
  body: '{"error":{"code":"$code","message":"m"}}',
  requestUri: Uri.parse('http://localhost/x'),
);
