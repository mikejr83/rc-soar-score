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
