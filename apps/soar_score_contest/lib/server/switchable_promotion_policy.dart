import 'package:soar_score_core/soar_score_core.dart' as core;

/// The embedded server's [core.PromotionIntentPolicy], settable after the
/// server started.
///
/// The server begins with adoptions written directly. The sync wiring, which
/// starts after the server and knows which contests sync, installs the real
/// policy with [use].
class SwitchablePromotionPolicy implements core.PromotionIntentPolicy {
  core.PromotionIntentPolicy _inner = const core.NoPromotionIntents();

  /// Decides from now on with [policy].
  void use(core.PromotionIntentPolicy policy) => _inner = policy;

  @override
  Future<bool> queuesPromotions(core.Id contestId) =>
      _inner.queuesPromotions(contestId);
}
