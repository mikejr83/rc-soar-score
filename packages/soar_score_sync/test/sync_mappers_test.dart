import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_sync/src/sync_mappers.dart';
import 'package:test/test.dart';

void main() {
  final scope = ContestScopeKey(Id.create());
  SyncChangeDto change(Map<String, Object?> payload) => SyncChangeDto(
    sequence: 3,
    entityType: 'Team',
    entityId: Id.create(),
    revision: 2,
    payload: payload,
  );

  test('a saved entity is applied as stored', () {
    final mapped = changeFromDto(scope, change({'id': 'x', 'name': 'A'}));

    expect(mapped.isDelete, isFalse);
    expect(mapped.payload, {'id': 'x', 'name': 'A'});
    expect(mapped.sequence, 3);
  });

  test('a deletion from the service is applied as a delete', () {
    final mapped = changeFromDto(scope, change({'deleted': true}));

    expect(mapped.isDelete, isTrue);
  });
}
