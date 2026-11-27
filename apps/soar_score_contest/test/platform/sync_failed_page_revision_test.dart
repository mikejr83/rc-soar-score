import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_sync/soar_score_sync.dart';

/// Regression test for #875: a pulled page with a Role creation, its
/// deletion and an unsupported change is replayed after the cursor refuses to
/// move past the unsupported change. The replay must not rewrite the
/// intermediate states, so the data revision must not move with it.
///
/// Uses the real applier and engine over a real database.
void main() {
  final director = core.Id.create();
  final scope = core.DirectorScopeKey(director);

  late SoarScoreDatabase database;
  late SyncEngine engine;
  late _Gateway gateway;

  setUp(() async {
    database = createInMemoryDatabase();
    gateway = _Gateway();
    engine = SyncEngine(
      store: DriftSyncStore(database),
      applier: DriftReplicatedChangeApplier(
        database,
        EntityStores.forDatabase(database),
      ),
      gateway: gateway,
      config: SyncEngineConfig(
        installationId: core.Id.create(),
        label: 'Field laptop',
        platform: core.Platform.windows,
        schemaVersion: database.schemaVersion,
      ),
    );
  });

  tearDown(() async {
    await engine.dispose();
    await database.close();
  });

  test(
    'replaying a failed page leaves the data revision where it was',
    () async {
      // First pull: the Role is created and then deleted; the unsupported
      // change stops the pull, so the cursor never moves.
      expect(await engine.syncScope(scope), SyncFailureKind.unsupportedChange);
      expect(await RoleRepository(database).findById(_Gateway.roleId), isNull);
      expect(await DriftSyncStore(database).readCursor(scope), 0);
      expect(engine.state.scopes[scope]!.dataRevision, 1);

      // The cursor did not move, so the same page is pulled again. The Role is
      // created and deleted again, and the final data is unchanged; the
      // revision must not move with the replay.
      expect(await engine.syncScope(scope), SyncFailureKind.unsupportedChange);
      expect(await RoleRepository(database).findById(_Gateway.roleId), isNull);
      expect(await DriftSyncStore(database).readCursor(scope), 0);
      expect(engine.state.scopes[scope]!.dataRevision, 1);
    },
    // After each pull the database and cursor are the same; only the first
    // pull may move the revision, because it is the one that stored the
    // intermediate states.
    //   pull 1: Role absent, cursor 0, dataRevision 1
    //   pull 2: Role absent, cursor 0, dataRevision 1
  );
}

/// Answers every exchange with the page that ends in an unsupported change.
class _Gateway implements SyncGateway {
  _Gateway();

  /// The Role the page creates and then deletes.
  static final roleId = core.Id.create();

  @override
  Future<SyncInfoDto> syncInfo() async => SyncInfoDto(
    protocolVersion: core.SyncProtocol.protocolVersion,
    minProtocolVersion: 1,
    minSchemaVersion: 1,
    maxSchemaVersion: 2,
    serverTime: DateTime.utc(2026, 11, 17),
  );

  @override
  Future<core.Installation> registerInstallation(
    RegisterInstallationRequest request,
  ) async => core.Installation(
    id: request.id,
    ownerAccountId: core.Id.create(),
    label: request.label,
    platform: request.platform,
    createdAt: DateTime.utc(2026, 11, 17),
  );

  @override
  Future<SyncExchangeResponse> exchange(SyncExchangeRequest request) async =>
      SyncExchangeResponse(
        protocolVersion: core.SyncProtocol.protocolVersion,
        results: const [],
        changes: _changes,
        conflicts: const [],
        serverSequence: 3,
      );

  @override
  Future<SystemDataResponse> systemData({
    required int afterSequence,
    String? pageToken,
  }) async =>
      SystemDataResponse(changes: const [], systemDataSeq: afterSequence);

  @override
  Future<SyncMutationResult> resolveConflict(
    core.Id conflictId,
    ResolveConflictRequest request, {
    required core.SyncScopeKey scope,
  }) async => SyncMutationResult(
    clientMutationId: request.clientMutationId,
    outcome: core.MutationOutcome.rejected,
    reasonCode: 'locked',
  );

  /// The pulled page: a Role created, then deleted, then an entity type the
  /// applier cannot store.
  static final _changes = [
    SyncChangeDto(
      sequence: 1,
      entityType: 'Role',
      entityId: roleId,
      revision: 1,
      payload: _rolePayload,
    ),
    SyncChangeDto(
      sequence: 2,
      entityType: 'Role',
      entityId: roleId,
      revision: 2,
      payload: const {'deleted': true},
    ),
    SyncChangeDto(
      sequence: 3,
      entityType: 'FlightResult',
      entityId: core.Id.create(),
      revision: 1,
      payload: const {},
    ),
  ];

  static final _rolePayload = {
    'id': roleId.value,
    'owner_account_id': null,
    'display_name': 'Timekeeper',
    'type': 'NonFlier',
    'archived_at': null,
    'revision': 1,
  };
}
