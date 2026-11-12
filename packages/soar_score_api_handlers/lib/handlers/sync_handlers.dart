import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/contest_authorization.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_core/soar_score_core.dart';

final _logger = Logger('Sync');

/// Adds the sync routes to [router] (which is mounted under `/api/v1`):
///
/// - `GET /sync/info` the protocol and schema ranges the service accepts
/// - `POST /installations`, `GET /installations`,
///   `POST /installations/{id}/revoke` register, list and revoke the caller's
///   installations
/// - `POST /contests/{contestId}/activations` makes an installation the
///   contest's administration installation
/// - `GET /sync/revision` where a scope's log stands, to learn cheaply
///   whether anything changed (`contest_id` picks a contest, else the
///   caller's own data)
/// - `POST /sync/exchange` pushes unsent mutations and pulls the changes
///   after the cursor for one scope
/// - `GET /sync/system-data` the pull-only system data stream
/// - `POST /sync/conflicts/{conflictId}/resolve` the director's decision for
///   a conflict
///
/// Specified in `plan/architecture-requirements/sync-protocol.md`. The
/// hosted server only: the embedded instance has no installations and
/// answers 409 `backend_only`. Problems with a single mutation are results in
/// the exchange response, never HTTP errors; the whole request is refused
/// only for a version outside the range (426 or 409), a revoked installation
/// (403) or an expired page token (410).
void addSyncRoutes(
  Router router,
  Repository repository, {
  required SyncVersions versions,
  RecalculationService? recalculation,
}) {
  final installations = InstallationSyncService(repository);
  // Results never sync, so the service rebuilds a contest's after it accepts
  // changes to it.
  final acceptor = SyncAcceptorService(
    repository,
    versions: versions,
    recalculation:
        recalculation ?? RecalculationService(ResultsService(repository)),
  );

  router.get(
    '/sync/info',
    (Request request) => jsonResponse(
      SyncInfoDto(
        protocolVersion: versions.protocolVersion,
        minProtocolVersion: versions.minProtocolVersion,
        minSchemaVersion: versions.minSchemaVersion,
        maxSchemaVersion: versions.maxSchemaVersion,
        serverTime: acceptor.serverTime,
      ).toJson(),
    ),
  );

  router.post('/installations', (Request request) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(
      request,
      RegisterInstallationRequest.fromJson,
    );
    _logger.info(
      'Registering installation for account ${principal.accountId} with id ${body.id}',
    );
    final installation = await installations.register(
      accountId: principal.accountId,
      id: body.id,
      label: body.label,
      platform: body.platform,
    );
    return jsonResponse(installation.toJson());
  });

  router.get('/installations', (Request request) async {
    final principal = requirePrincipal(request);
    _logger.fine('Listing installations for account ${principal.accountId}');
    final found = await installations.list(principal.accountId);
    _logger.fine(
      'Found ${found.length} installations for account ${principal.accountId}',
    );
    return jsonResponse(<String, dynamic>{
      'installations': [for (final i in found) i.toJson()],
    });
  });

  router.post('/installations/<id>/revoke', (Request request, String id) async {
    final principal = requirePrincipal(request);
    final installation = await installations.revoke(
      accountId: principal.accountId,
      id: Id.parse(id),
    );
    _logger.fine('Revoked installation $id for account ${principal.accountId}');
    return jsonResponse(installation.toJson());
  });

  router.post('/contests/<contestId>/activations', (
    Request request,
    String contestId,
  ) async {
    final principal = requirePrincipal(request);
    final id = Id.parse(contestId);
    // The contest's director, before the body is read. The installation's
    // owner is a different check and stays in the service.
    await requireContestDirector(request, repository, id);
    final body = await readJsonBody(
      request,
      ActivateInstallationRequest.fromJson,
    );
    final activation = await installations.activate(
      accountId: principal.accountId,
      contestId: id,
      installationId: body.installationId,
      kind: body.kind,
    );
    return jsonResponse(activation.toJson());
  });

  router.get('/sync/revision', (Request request) async {
    final principal = requirePrincipal(request);
    final raw = request.url.queryParameters['contest_id'];
    final Id? contestId;
    try {
      contestId = raw == null ? null : Id.parse(raw);
    } on ArgumentError {
      throw ArgumentError.value(raw, 'contest_id', 'is not a contest id');
    }
    // Unlike an exchange, which must accept the first upload of a contest the
    // service does not hold yet, a read needs a contest that exists and is the
    // caller's: a deleted contest keeps its log, which is not for anyone else.
    if (contestId != null) {
      await requireContestDirector(request, repository, contestId);
    }
    final sequence = await acceptor.revision(
      accountId: principal.accountId,
      scope: contestId == null
          ? DirectorScopeKey(principal.accountId)
          : ContestScopeKey(contestId),
    );
    return jsonResponse(
      SyncRevisionDto(
        accountId: principal.accountId,
        contestId: contestId,
        sequence: sequence,
      ).toJson(),
    );
  });

  router.post('/sync/exchange', (Request request) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(request, SyncExchangeRequest.fromJson);
    final output = await acceptor.exchange(
      accountId: principal.accountId,
      input: SyncExchangeInput(
        protocolVersion: body.protocolVersion,
        schemaVersion: body.schemaVersion,
        installationId: body.installationId,
        scope: _scopeOf(body.scope),
        lastAcknowledgedSequence: body.lastAcknowledgedSequence,
        pageToken: body.pageToken,
        mutations: [
          for (final m in body.mutations)
            SyncMutation(
              id: m.id,
              clientMutationId: m.clientMutationId,
              entityType: m.entityType,
              entityId: m.entityId,
              baseRevision: m.baseRevision,
              authority: m.authority,
              clientTime: m.clientTime,
              dependsOnMutationId: m.dependsOnMutationId,
              payload: m.payload,
            ),
        ],
      ),
    );
    return jsonResponse(
      SyncExchangeResponse(
        protocolVersion: versions.protocolVersion,
        results: [for (final r in output.results) _resultOf(r)],
        changes: [for (final c in output.changes) _changeOf(c)],
        conflicts: [
          for (final c in output.conflicts)
            SyncConflictRef(id: c.id, requiresAction: c.requiresAction),
        ],
        nextPageToken: output.nextPageToken,
        serverSequence: output.serverSequence,
      ).toJson(),
    );
  });

  router.get('/sync/system-data', (Request request) {
    requirePrincipal(request);
    final after = int.tryParse(
      request.url.queryParameters['after_sequence'] ?? '',
    );
    if (after == null || after < 0) {
      throw ArgumentError('after_sequence must be a non-negative integer.');
    }
    final page = acceptor.systemData(afterSequence: after);
    return jsonResponse(
      SystemDataResponse(
        changes: [for (final c in page.changes) _changeOf(c)],
        systemDataSeq: page.systemDataSeq,
      ).toJson(),
    );
  });

  router.post('/sync/conflicts/<conflictId>/resolve', (
    Request request,
    String conflictId,
  ) async {
    final principal = requirePrincipal(request);
    final id = Id.parse(conflictId);
    // The decider of the conflict's scope, before the body is read.
    await acceptor.requireConflictDecider(
      accountId: principal.accountId,
      conflictId: id,
    );
    final body = await readJsonBody(request, ResolveConflictRequest.fromJson);
    _logger.info(
      'Resolving conflict $conflictId for account ${principal.accountId}',
    );
    final result = await acceptor.resolveConflict(
      accountId: principal.accountId,
      conflictId: id,
      clientMutationId: body.clientMutationId,
      choice: body.choice,
      payload: body.payload,
    );
    return jsonResponse(_resultOf(result).toJson());
  });
}

SyncScopeKey _scopeOf(SyncScopeDto scope) => scope.contestId != null
    ? ContestScopeKey(scope.contestId!)
    : DirectorScopeKey(scope.ownerAccountId!);

SyncMutationResult _resultOf(MutationResult r) => SyncMutationResult(
  clientMutationId: r.clientMutationId,
  outcome: r.outcome,
  revision: r.revision,
  sequence: r.sequence,
  reasonCode: r.reasonCode,
  currentRevision: r.currentRevision,
  dependsOn: r.dependsOn,
);

SyncChangeDto _changeOf(AcceptedChange c) => SyncChangeDto(
  sequence: c.sequence,
  entityType: c.entityType,
  entityId: c.entityId,
  revision: c.revision,
  payload: c.payload,
);
