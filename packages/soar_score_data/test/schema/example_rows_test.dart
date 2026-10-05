import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../support/example_rows.dart';
import '../support/fixtures.dart';

/// Loads the documented example rows (`plan/data-model/examples/entities`)
/// through the entity stores and reads them back: each row must persist as
/// written, with its foreign keys satisfied by the other examples.
///
/// Entities are listed parents first. Each PR that adds tables extends the
/// list until all 48 are covered.
const _entities = <(String entity, String file)>[
  ('Contest', 'contest'),
  ('LandingTable', 'landing_table'),
  ('LandingResult', 'landing_result'),
  ('DisciplineProfile', 'discipline_profile'),
  ('DisciplineConfigField', 'discipline_configfield'),
  ('DisciplineScoreField', 'discipline_scorefield'),
  ('DisciplineValidation', 'discipline_validation'),
  ('DisciplineFormula', 'discipline_formula'),
  ('DisciplineRule', 'discipline_rule'),
  ('ContestConfigurationPreset', 'contest_configuration_preset'),
  ('ContestConfigurationRevision', 'contest_configuration_revision'),
  ('ParticipantProfile', 'participant_profile'),
  ('Role', 'role'),
  ('ContestParticipation', 'contest_participation'),
  ('Team', 'team'),
  ('TeamMembership', 'team_membership'),
  ('ModelCatalog', 'model_catalog'),
  ('ContestModelLink', 'contest_model_link'),
];

void main() {
  late Installation inst;
  setUp(() => inst = Installation.open());
  tearDown(() => inst.db.close());

  test('every example row persists and reads back as written', () async {
    for (final (entity, file) in _entities) {
      final rows = exampleRows(file);
      final store = inst.stores.of(entity);
      for (final (i, row) in rows.indexed) {
        await store.upsertJson(row);
        final back = await store.findJson(core.Id.parse(row['id']! as String));
        expect(
          store.encode(store.decode(back!)),
          equals(row),
          reason: '$entity #$i',
        );
      }
    }
  });
}
