import 'package:soar_score_core/soar_score_core.dart';

import 'example_registry.dart';

/// The entities the example harness can round-trip.
///
/// Each model PR adds its entities here.
ExampleRegistry buildExampleRegistry() => ExampleRegistry()
  ..register('AuditEvent', (json) => AuditEvent.fromJson(json).toJson())
  ..register('ConflictRecord', (json) => ConflictRecord.fromJson(json).toJson())
  ..register('Contest', (json) => Contest.fromJson(json).toJson())
  ..register(
    'ContestConfigurationPreset',
    (json) => ContestConfigurationPreset.fromJson(json).toJson(),
  )
  ..register(
    'ContestConfigurationRevision',
    (json) => ContestConfigurationRevision.fromJson(json).toJson(),
  )
  ..register(
    'DisciplineConfigField',
    (json) => DisciplineConfigField.fromJson(json).toJson(),
  )
  ..register(
    'DisciplineFormula',
    (json) => DisciplineFormula.fromJson(json).toJson(),
  )
  ..register(
    'DisciplineProfile',
    (json) => DisciplineProfile.fromJson(json).toJson(),
  )
  ..register('DisciplineRule', (json) => DisciplineRule.fromJson(json).toJson())
  ..register(
    'DisciplineScoreField',
    (json) => DisciplineScoreField.fromJson(json).toJson(),
  )
  ..register(
    'DisciplineValidation',
    (json) => DisciplineValidation.fromJson(json).toJson(),
  )
  ..register('LandingResult', (json) => LandingResult.fromJson(json).toJson())
  ..register('LandingTable', (json) => LandingTable.fromJson(json).toJson())
  ..register(
    'ContestModelLink',
    (json) => ContestModelLink.fromJson(json).toJson(),
  )
  ..register(
    'ContestParticipation',
    (json) => ContestParticipation.fromJson(json).toJson(),
  )
  ..register('ModelCatalog', (json) => ModelCatalog.fromJson(json).toJson())
  ..register(
    'ParticipantProfile',
    (json) => ParticipantProfile.fromJson(json).toJson(),
  )
  ..register('Role', (json) => Role.fromJson(json).toJson())
  ..register('Team', (json) => Team.fromJson(json).toJson())
  ..register('TeamMembership', (json) => TeamMembership.fromJson(json).toJson())
  ..register(
    'MatrixAssignment',
    (json) => MatrixAssignment.fromJson(json).toJson(),
  )
  ..register('MatrixRevision', (json) => MatrixRevision.fromJson(json).toJson())
  ..register('ReFlight', (json) => ReFlight.fromJson(json).toJson())
  ..register(
    'ReFlightParticipant',
    (json) => ReFlightParticipant.fromJson(json).toJson(),
  )
  ..register('Round', (json) => Round.fromJson(json).toJson())
  ..register('RoundGroup', (json) => RoundGroup.fromJson(json).toJson())
  ..register('OfficialScore', (json) => OfficialScore.fromJson(json).toJson())
  ..register('ReviewRequest', (json) => ReviewRequest.fromJson(json).toJson())
  ..register('ScoreAttempt', (json) => ScoreAttempt.fromJson(json).toJson())
  ..register(
    'ScorePlaceholder',
    (json) => ScorePlaceholder.fromJson(json).toJson(),
  )
  ..register('Invitation', (json) => Invitation.fromJson(json).toSyncJson())
  ..register('Installation', (json) => Installation.fromJson(json).toJson())
  ..register(
    'InstallationActivation',
    (json) => InstallationActivation.fromJson(json).toJson(),
  )
  ..register('MutationRecord', (json) => MutationRecord.fromJson(json).toJson())
  ..register('SyncCursor', (json) => SyncCursor.fromJson(json).toJson())
  ..register('Tombstone', (json) => Tombstone.fromJson(json).toJson());
