import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import 'drift_repository.dart';

/// Contest configuration revisions in [SoarScoreDatabase]; append-only.
class ContestConfigurationRevisionRepository extends DriftRepository
    implements core.ContestConfigurationRevisionRepository {
  ContestConfigurationRevisionRepository(super.db, {super.stores});

  late final _store = store<core.ContestConfigurationRevision>(
    'ContestConfigurationRevision',
  );

  @override
  Future<core.ContestConfigurationRevision?> findById(core.Id id) =>
      _store.find(id);

  @override
  Future<List<core.ContestConfigurationRevision>> listForContest(
    core.Id contestId,
  ) => _store.whereId('contest_id', contestId, orderBy: 'revision_number');

  @override
  Future<core.ContestConfigurationRevision?> latestForContest(
    core.Id contestId,
  ) async {
    final revisions = await listForContest(contestId);
    return revisions.isEmpty ? null : revisions.last;
  }

  @override
  Future<core.ContestConfigurationRevision> append(
    core.ContestConfigurationRevision revision, {
    required core.MutationMetadata metadata,
  }) =>
      unitOfWork.run((context) => context.append(revision, metadata: metadata));
}
