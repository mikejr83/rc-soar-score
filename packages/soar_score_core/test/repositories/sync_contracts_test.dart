import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../models/sync/ids.dart';

class _Entity implements Synchronizable {
  @override
  Id get id => exampleId(1);
  @override
  String get entityType => 'Team';
  @override
  int get revision => 0;
  @override
  SyncScope get syncScope => SyncScope.contest;
}

void main() {
  group('SyncScopeKey', () {
    test('compares by the identifier it holds', () {
      expect(ContestScopeKey(exampleId(1)), ContestScopeKey(exampleId(1)));
      expect(
        ContestScopeKey(exampleId(1)),
        isNot(ContestScopeKey(exampleId(2))),
      );
      expect(
        ContestScopeKey(exampleId(1)),
        isNot(DirectorScopeKey(exampleId(1))),
      );
    });

    test('can be switched over exhaustively', () {
      String name(SyncScopeKey key) => switch (key) {
        ContestScopeKey() => 'contest',
        DirectorScopeKey() => 'director',
      };
      expect(name(ContestScopeKey(exampleId(1))), 'contest');
      expect(name(DirectorScopeKey(exampleId(1))), 'director');
    });
  });

  test('MutationMetadata compares by value', () {
    MutationMetadata make(String id) => MutationMetadata(
      clientMutationId: id,
      authority: Authority.director,
      clientTime: t0,
    );
    expect(make('a'), make('a'));
    expect(make('a'), isNot(make('b')));
  });

  test('ReplicatedChange compares by value', () {
    ReplicatedChange make({bool isDelete = false}) => ReplicatedChange(
      scope: ContestScopeKey(exampleId(1)),
      sequence: 5,
      entityType: 'Team',
      entityId: exampleId(2),
      revision: 3,
      payload: const {'name': 'Boulder Thermals'},
      isDelete: isDelete,
    );
    expect(make(), make());
    expect(make(), isNot(make(isDelete: true)));
  });

  test('SyncStatus compares by value', () {
    const a = SyncStatus(
      pendingMutations: 1,
      conflictsNeedingAction: 0,
      lastSyncedSequence: 7,
    );
    expect(
      a,
      const SyncStatus(
        pendingMutations: 1,
        conflictsNeedingAction: 0,
        lastSyncedSequence: 7,
      ),
    );
  });

  test('a synchronizable entity carries its identity, type and revision', () {
    final entity = _Entity();
    expect(entity, isA<SyncScoped>());
    expect(
      [entity.id, entity.entityType, entity.revision],
      [exampleId(1), 'Team', 0],
    );
  });
}
