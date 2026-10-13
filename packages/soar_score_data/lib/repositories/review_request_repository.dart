import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

/// Review requests in the database.
class ReviewRequestRepository extends DriftRepository
    implements core.ReviewRequestRepository {
  ReviewRequestRepository(super.db, {super.stores});

  late final _store = store<core.ReviewRequest>('ReviewRequest');

  @override
  Future<core.ReviewRequest?> findById(core.Id id) => _store.find(id);

  @override
  Future<List<core.ReviewRequest>> listForContest(core.Id contestId) =>
      _store.whereId('contest_id', contestId, orderBy: 'id');

  @override
  Future<List<core.ReviewRequest>> listForScorePlaceholder(
    core.Id scorePlaceholderId,
  ) =>
      _store.whereId('score_placeholder_id', scorePlaceholderId, orderBy: 'id');

  @override
  Future<core.ReviewRequest?> findOpenForScorePlaceholder(
    core.Id scorePlaceholderId,
  ) async {
    final all = await listForScorePlaceholder(scorePlaceholderId);
    return all.where((r) => r.isOpen).firstOrNull;
  }

  @override
  Future<List<core.ReviewRequest>> listOpenForContest(core.Id contestId) async {
    final all = await listForContest(contestId);
    return all.where((r) => r.isOpen).toList();
  }

  @override
  Future<core.ReviewRequest> save(
    core.ReviewRequest request, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) => context.save(request, metadata: metadata));
}
