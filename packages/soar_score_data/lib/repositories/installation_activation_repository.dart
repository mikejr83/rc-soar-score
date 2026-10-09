import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Installation activations in the database; backend only, so written without
/// a mutation.
class InstallationActivationRepository extends DriftRepository
    implements core.InstallationActivationRepository {
  InstallationActivationRepository(super.db, {super.stores});

  late final _store = backendStore<core.InstallationActivation>(
    'InstallationActivation',
  );

  @override
  Future<core.InstallationActivation?> findById(core.Id id) async =>
      _store.find(id);

  @override
  Future<core.InstallationActivation?> findOpen({
    required core.Id contestId,
    required core.Id installationId,
  }) async {
    final found = await listForContest(contestId);
    return found
        .where((a) => a.installationId == installationId && a.isOpen)
        .firstOrNull;
  }

  @override
  Future<List<core.InstallationActivation>> listForContest(
    core.Id contestId,
  ) async => _store.whereId('contest_id', contestId, orderBy: 'id');

  @override
  Future<List<core.InstallationActivation>> listForInstallation(
    core.Id installationId,
  ) async => _store.whereId('installation_id', installationId, orderBy: 'id');

  @override
  Future<core.InstallationActivation> save(
    core.InstallationActivation activation,
  ) async {
    await _store.upsertJson(_store.encode(activation));
    return activation;
  }

  @override
  Future<bool> remove(core.Id id) async => _store.remove(id);
}
