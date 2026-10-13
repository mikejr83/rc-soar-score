import 'package:soar_score_sync/soar_score_sync.dart';
import 'package:test/test.dart';

import '../support/fake_gateway.dart';
import '../support/fixtures.dart';

void main() {
  test('refresh reads the store without contacting the service', () async {
    final rig = Rig();
    rig.store.mutations.add(mutation(1));

    await rig.engine.refresh(scope);

    expect(rig.engine.state.scopes[scope]!.pendingMutations, 1);
    expect(rig.gateway.exchanges, isEmpty);
    expect(rig.gateway.infoCalls, 0);
  });

  test('refresh keeps the failure of the last attempt', () async {
    final rig = Rig();
    rig.gateway.onExchange = (_) async => throw httpError(500);

    await rig.engine.syncScope(scope);
    await rig.engine.refresh(scope);

    expect(
      rig.engine.state.scopes[scope]!.failure,
      SyncFailureKind.serverError,
    );
  });

  test('refresh marks a scope that is not syncable', () async {
    final rig = Rig(syncable: (_) => false);

    await rig.engine.refresh(scope);

    expect(
      rig.engine.state.scopes[scope]!.skipReason,
      SyncSkipReason.accountless,
    );
  });
}
