import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Contest configuration presets in the database.
class ContestConfigurationPresetRepository extends DriftRepository
    implements core.ContestConfigurationPresetRepository {
  ContestConfigurationPresetRepository(super.db, {super.stores});

  late final _store = store<core.ContestConfigurationPreset>(
    'ContestConfigurationPreset',
  );

  @override
  Future<core.ContestConfigurationPreset?> findById(core.Id id) =>
      _store.find(id);

  @override
  Future<List<core.ContestConfigurationPreset>> listForOwner(
    core.Id ownerAccountId,
  ) => _store.whereId('owner_account_id', ownerAccountId, orderBy: 'name, id');

  @override
  Future<core.ContestConfigurationPreset> save(
    core.ContestConfigurationPreset preset, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) => context.save(preset, metadata: metadata));

  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      unitOfWork.run((context) async {
        final preset = await _store.find(id);
        if (preset == null) return false;
        await context.delete(preset, metadata: metadata);
        return true;
      });
}
