import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

/// Marking a score official is queued as a `promote_score` intent when the
/// contest syncs and its first upload has finished; otherwise it is written
/// directly, and the first upload carries it.
///
/// A contest this installation created uploads its creation and whole history
/// first, and that creation stays pending until the upload is done (see
/// [PromotionIntentRepository.firstUploadOpen]).
class NativePromotionIntents implements core.PromotionIntentPolicy {
  NativePromotionIntents(SoarScoreDatabase database, this._isSyncable)
    : _intents = PromotionIntentRepository(database);

  final PromotionIntentRepository _intents;
  final Future<bool> Function(core.SyncScopeKey scope) _isSyncable;

  @override
  Future<bool> queuesPromotions(core.Id contestId) async =>
      await _isSyncable(core.ContestScopeKey(contestId)) &&
      !await _intents.firstUploadOpen(contestId);
}
