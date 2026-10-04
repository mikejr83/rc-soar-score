import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

PublicationProjection make({
  int revision = 1,
  int rules = 1,
  String mutationId = '01J9ZP5B2E4G6H8K0N2Q4S6U8W',
  Map<String, Object?> identity = const {'name': 'Front Range ALES Open'},
}) => PublicationProjection(
  id: exampleId(1),
  publicationId: exampleId(2),
  projectionRevision: revision,
  contestRevision: 7,
  configRevision: 2,
  matrixRevision: 1,
  disciplineType: DisciplineType.ales,
  disciplineRulesVersion: rules,
  calculationVersion: '1.0.0',
  contestIdentity: identity,
  participants: const [
    {'pilot_key': 'p_7Hq2xK', 'participant_number': 1},
  ],
  standings: const {'pilots': []},
  publishedAt: t0,
  clientMutationId: mutationId,
);

void main() {
  group('PublicationProjection', () {
    test('round trips with the discipline text', () {
      final p = make();
      expect(p.toJson()['discipline_type'], 'ALES');
      expect(p.toJson()['published_by'], isNull);
      expect(PublicationProjection.fromJson(p.toJson()), p);
      expect(p, isA<BackendOnly>());
    });

    test('is not private data', () {
      expect(make(), isNot(isA<PrivateData>()));
    });

    test('the first projection is revision 1', () {
      expect(() => make(revision: 0), throwsArgumentError);
    });

    test('rules version starts at 1', () {
      expect(() => make(rules: 0), throwsArgumentError);
    });

    test('needs an idempotency key', () {
      expect(() => make(mutationId: ' '), throwsArgumentError);
    });

    test('copies the content so later edits do not leak in', () {
      final identity = <String, Object?>{'name': 'A'};
      final p = make(identity: identity);
      identity['name'] = 'B';
      expect(p.contestIdentity['name'], 'A');
    });
  });
}
