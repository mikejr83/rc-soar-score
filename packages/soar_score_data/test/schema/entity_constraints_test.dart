import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/example_rows.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  setUp(() async => inst = await Installation.open(backend));
  tearDown(() => inst.close());

  Future<void> put(String entity, Map<String, Object?> row) =>
      inst.stores.of(entity).upsertJson(row);

  Map<String, Object?> example(String file) => {...exampleRows(file).first};

  String newId() => core.Id.create().value;

  Future<void> loadContest() => put('Contest', example('contest'));

  group('foreign keys', () {
    test('refuse a row whose parent is missing', () async {
      await expectLater(put('Team', example('team')), throwsA(anything));
    });

    test('accept a row whose parent exists', () async {
      await loadContest();
      await put('Team', example('team'));
    });

    test('deleting a contest removes its contest data only', () async {
      await loadContest();
      final team = example('team');
      await put('Team', team);
      expect(await inst.count('teams'), 1);

      await inst.stores
          .of('Contest')
          .remove(core.Id.parse(team['contest_id']! as String));
      expect(await inst.count('teams'), 0);
    });

    test('deleting a parent that still has children is refused', () async {
      await put('LandingTable', example('landing_table'));
      final result = example('landing_result');
      await put('LandingResult', result);
      await expectLater(
        inst.stores
            .of('LandingTable')
            .remove(core.Id.parse(result['landing_table_id']! as String)),
        throwsA(anything),
      );
    });
  });

  group('unique keys', () {
    test('a team name is unique within a contest', () async {
      await loadContest();
      final team = example('team');
      await put('Team', team);
      await expectLater(
        put('Team', {...team, 'id': newId()}),
        throwsA(anything),
      );
    });
  });

  group('custom indexes', () {
    Map<String, Object?> role(
      String name, {
      String? owner,
      String type = 'NonFlier',
    }) => {
      ...example('role'),
      'id': newId(),
      'display_name': name,
      'owner_account_id': owner,
      'type': type,
    };

    test(
      'role names are unique ignoring case, system roles share one namespace',
      () async {
        await put('Role', role('Scorer'));
        await expectLater(put('Role', role('SCORER')), throwsA(anything));
        final owner = newId();
        await put('Role', role('Scorer', owner: owner));
        await expectLater(
          put('Role', role('scorer', owner: owner)),
          throwsA(anything),
        );
      },
    );

    test('only one role is the Pilot role', () async {
      await put('Role', role('Pilot', type: 'Pilot'));
      await expectLater(
        put('Role', role('Flier', type: 'Pilot')),
        throwsA(anything),
      );
    });

    test(
      'a model name without a manufacturer is unique within an owner',
      () async {
        final base = {...example('model_catalog'), 'manufacturer': null};
        await put('ModelCatalog', base);
        await expectLater(
          put('ModelCatalog', {...base, 'id': newId()}),
          throwsA(anything),
        );
        await put('ModelCatalog', {
          ...base,
          'id': newId(),
          'owner_account_id': newId(),
        });
      },
    );

    test('only one formula per profile is primary', () async {
      await put('LandingTable', example('landing_table'));
      await put('DisciplineProfile', example('discipline_profile'));
      final formula = {...example('discipline_formula'), 'is_primary': true};
      await put('DisciplineFormula', formula);
      await expectLater(
        put('DisciplineFormula', {
          ...formula,
          'id': newId(),
          'formula_key': 'other',
        }),
        throwsA(anything),
      );
    });
  });
}
