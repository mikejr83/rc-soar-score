import 'package:soar_score_core/soar_score_core.dart';

import 'example_registry.dart';

/// The entities the example harness can round-trip.
///
/// Each model PR adds its entities here.
ExampleRegistry buildExampleRegistry() => ExampleRegistry()
  ..register('AuditEvent', (json) => AuditEvent.fromJson(json).toJson())
  ..register('ConflictRecord', (json) => ConflictRecord.fromJson(json).toJson())
  ..register('Installation', (json) => Installation.fromJson(json).toJson())
  ..register(
    'InstallationActivation',
    (json) => InstallationActivation.fromJson(json).toJson(),
  )
  ..register('MutationRecord', (json) => MutationRecord.fromJson(json).toJson())
  ..register('SyncCursor', (json) => SyncCursor.fromJson(json).toJson())
  ..register('Tombstone', (json) => Tombstone.fromJson(json).toJson());
