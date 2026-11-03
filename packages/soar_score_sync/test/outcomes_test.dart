import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_sync/soar_score_sync.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  test(
    'a completed sync reports no failure, an offline one reports it',
    () async {
      final rig = Rig();
      final outcomes = <SyncFailureKind?>[];
      final subscription = rig.engine.outcomes.listen(outcomes.add);
      addTearDown(subscription.cancel);

      await rig.engine.syncScope(scope);
      rig.gateway.onExchange = (_) async =>
          throw ApiNetworkError('down', requestUri: Uri.parse('http://x'));
      await rig.engine.syncScope(scope);
      await Future<void>.delayed(Duration.zero);

      expect(outcomes, [null, SyncFailureKind.offline]);
    },
  );
}
