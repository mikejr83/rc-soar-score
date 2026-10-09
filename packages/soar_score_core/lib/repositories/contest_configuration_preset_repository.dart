import '../models/contest/contest_configuration_preset.dart';
import '../models/id.dart';
import 'mutation_metadata.dart';

/// Abstract persistence contract for a director's
/// [ContestConfigurationPreset]s.
abstract interface class ContestConfigurationPresetRepository {
  Future<ContestConfigurationPreset?> findById(Id id);

  /// The presets owned by [ownerAccountId], by name.
  Future<List<ContestConfigurationPreset>> listForOwner(Id ownerAccountId);

  /// Stores [preset], bumping its revision, and records one mutation.
  ///
  /// Throws a `StaleRevisionError`, storing nothing, when [preset] was read
  /// at an older revision than the stored one.
  Future<ContestConfigurationPreset> save(
    ContestConfigurationPreset preset, {
    required MutationMetadata metadata,
  });

  /// Removes the preset [id] and records one mutation; returns `false` when
  /// it is not stored.
  Future<bool> delete(Id id, {required MutationMetadata metadata});
}
