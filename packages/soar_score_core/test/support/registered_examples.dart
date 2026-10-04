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
  ..register('Installation', (json) => Installation.fromJson(json).toJson())
  ..register(
    'InstallationActivation',
    (json) => InstallationActivation.fromJson(json).toJson(),
  )
  ..register('MutationRecord', (json) => MutationRecord.fromJson(json).toJson())
  ..register('SyncCursor', (json) => SyncCursor.fromJson(json).toJson())
  ..register('Tombstone', (json) => Tombstone.fromJson(json).toJson());
