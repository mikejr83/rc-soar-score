import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_sync/soar_score_sync.dart';

import 'fake_applier.dart';
import 'fake_gateway.dart';
import 'fake_store.dart';

final contestId = Id.parse('019c0000-0000-7000-8000-000000000020');
final installationId = Id.parse('019c0000-0000-7000-8000-000000000070');
final scope = ContestScopeKey(contestId);

Id idN(int n) =>
    Id.parse('019c0000-0000-7000-8000-${n.toString().padLeft(12, '0')}');

MutationRecord mutation(
  int n, {
  Id? dependsOn,
  String? clientId,
  Map<String, Object?>? payload,
}) => MutationRecord(
  id: idN(1000 + n),
  contestId: contestId,
  entityType: 'official_score',
  entityId: idN(2000 + n),
  baseRevision: 1,
  clientMutationId: clientId ?? 'm-$n',
  authority: Authority.director,
  clientTime: DateTime.utc(2026, 10, 13, 12, n),
  payload: payload ?? {'n': n},
  dependsOnMutationId: dependsOn,
);

SyncChangeDto change(int sequence) => SyncChangeDto(
  sequence: sequence,
  entityType: 'official_score',
  entityId: idN(3000 + sequence),
  revision: 1,
  payload: {'seq': sequence},
);

SyncMutationResult accepted(String clientId, int sequence) =>
    SyncMutationResult(
      clientMutationId: clientId,
      outcome: MutationOutcome.accepted,
      revision: 2,
      sequence: sequence,
    );

/// An engine over fakes that share one event [log].
class Rig {
  Rig({
    bool Function(SyncScopeKey)? syncable,
    int maxBytes = syncExchangeMaxBodyBytes,
    int maxMutations = syncExchangeMaxMutations,
  }) {
    store = FakeSyncStore(log);
    applier = FakeApplier(log);
    gateway = FakeGateway(log);
    applier.store = store;
    engine = SyncEngine(
      store: store,
      applier: applier,
      gateway: gateway,
      config: SyncEngineConfig(
        installationId: installationId,
        label: 'Field laptop',
        platform: Platform.windows,
        schemaVersion: 1,
        maxExchangeBytes: maxBytes,
        maxExchangeMutations: maxMutations,
        now: () => DateTime.utc(2026, 10, 13, 15),
        isSyncable: syncable == null ? null : (s) async => syncable(s),
      ),
    );
  }

  final log = <String>[];
  late final FakeSyncStore store;
  late final FakeApplier applier;
  late final FakeGateway gateway;
  late final SyncEngine engine;
}

/// A service that lists `promote_score`.
SyncInfoDto infoWithPromotion() => SyncInfoDto(
  protocolVersion: 1,
  minProtocolVersion: 1,
  minSchemaVersion: 1,
  maxSchemaVersion: 1,
  serverTime: DateTime.utc(2026, 10, 13),
  capabilities: const [SyncCapabilities.promoteScore],
);

/// A `promote_score` intent in the outbox.
MutationRecord intent(int n, {String? clientId}) => MutationRecord(
  id: idN(4000 + n),
  contestId: contestId,
  entityType: promotionReceiptEntityType,
  entityId: idN(5000 + n),
  clientMutationId: clientId ?? 'p-$n',
  authority: Authority.director,
  clientTime: DateTime.utc(2026, 10, 13, 12, n),
  payload: {
    'version': 1,
    'data': {
      'operation': 'promote_score',
      'operation_version': 1,
      'assignment_id': idN(6000 + n).value,
      'source_attempt_id': idN(7000 + n).value,
      'expected_score_revision': 0,
    },
  },
);

/// The changes of one adoption: a score, its slot and the intent's receipt.
List<SyncChangeDto> adoption(int n, {required int from, Id? aggregate}) {
  final id = aggregate ?? idN(8000 + n);
  return [
    SyncChangeDto(
      sequence: from,
      entityType: 'OfficialScore',
      entityId: idN(9000 + n),
      revision: 1,
      payload: {'n': n},
      aggregateId: id,
    ),
    SyncChangeDto(
      sequence: from + 1,
      entityType: 'ScorePlaceholder',
      entityId: idN(9100 + n),
      revision: 2,
      payload: {'n': n},
      aggregateId: id,
    ),
    SyncChangeDto(
      sequence: from + 2,
      entityType: promotionReceiptEntityType,
      entityId: idN(5000 + n),
      revision: 0,
      payload: {'version': 1, 'data': {}},
      aggregateId: id,
    ),
  ];
}
