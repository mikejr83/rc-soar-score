import 'example_rows.dart';
import 'fixtures.dart';

/// The entities with documented example rows
/// (`plan/data-model/examples/entities`), parents first. Each PR that adds
/// tables extends the list until all 48 are covered.
const exampleEntities = <(String entity, String file)>[
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
  ('MatrixRevision', 'matrix_revision'),
  ('Round', 'round'),
  ('RoundGroup', 'round_group'),
  ('ReFlight', 're_flight'),
  ('MatrixAssignment', 'matrix_assignment'),
  ('ReFlightParticipant', 're_flight_participant'),
  ('ScorePlaceholder', 'score_placeholder'),
  ('ScoreAttempt', 'score_attempt'),
  ('OfficialScore', 'official_score'),
  ('ReviewRequest', 'review_request'),
  ('FlightResult', 'flight_result'),
  ('ParticipationStanding', 'participation_standing'),
  ('TeamStanding', 'team_standing'),
];

/// Stores every example row of [entities] (all of them by default) through
/// the entity stores, so a test can start from a full contest.
Future<void> loadExamples(Installation inst, {Iterable<String>? only}) async {
  for (final (entity, file) in exampleEntities) {
    if (only != null && !only.contains(entity)) continue;
    final store = inst.stores.of(entity);
    for (final row in exampleRows(file)) {
      await store.upsertJson(row);
    }
  }
}
