import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

void main() {
  group('Team', () {
    test('round trips and is contest data', () {
      final t = Team(id: exampleId(1), contestId: exampleId(2), name: 'Red');
      expect(Team.fromJson(t.toJson()), t);
      expect(t.syncScope, SyncScope.contest);
      expect(t.revision, 0);
    });

    test('needs a name', () {
      expect(
        () => Team(id: exampleId(1), contestId: exampleId(2), name: ' '),
        throwsArgumentError,
      );
    });
  });

  group('TeamMembership', () {
    test('round trips and carries the contest for sync scoping', () {
      final m = TeamMembership(
        id: exampleId(1),
        teamId: exampleId(2),
        contestParticipationId: exampleId(3),
        contestId: exampleId(4),
      );
      expect(TeamMembership.fromJson(m.toJson()), m);
      expect(m.toJson()['contest_id'], exampleId(4).toString());
      expect(m.syncScope, SyncScope.contest);
    });
  });

  group('ModelCatalog', () {
    test('round trips and is director data', () {
      final m = ModelCatalog(
        id: exampleId(1),
        ownerAccountId: exampleId(5),
        participantProfileId: exampleId(6),
        name: 'Supra',
        manufacturer: "Vladimir's Model",
        modelId: 'SUPRA-1',
      );
      expect(ModelCatalog.fromJson(m.toJson()), m);
      expect(m.syncScope, SyncScope.director);
    });

    test('manufacturer is optional, name is not', () {
      expect(
        ModelCatalog(
          id: exampleId(1),
          ownerAccountId: exampleId(5),
          participantProfileId: exampleId(6),
          name: 'Supra',
        ).manufacturer,
        null,
      );
      expect(
        () => ModelCatalog(
          id: exampleId(1),
          ownerAccountId: exampleId(5),
          participantProfileId: exampleId(6),
          name: '',
        ),
        throwsArgumentError,
      );
    });
  });

  group('ContestModelLink', () {
    ContestModelLink link({String? modelId = 'SUPRA-1'}) => ContestModelLink(
      id: exampleId(1),
      contestId: exampleId(2),
      contestParticipationId: exampleId(3),
      modelName: 'Supra',
      modelId: modelId,
    );

    test('round trips and is contest data', () {
      final l = link();
      expect(ContestModelLink.fromJson(l.toJson()), l);
      expect(l.syncScope, SyncScope.contest);
      expect(l.modelCatalogId, isNull);
    });

    test('needs a model name; the model id is optional but not blank', () {
      expect(() => link(modelId: ' '), throwsArgumentError);
      expect(link(modelId: null).modelId, isNull);
    });
  });
}
