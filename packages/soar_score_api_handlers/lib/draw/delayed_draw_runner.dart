import 'dart:async';

import 'package:soar_score_core/soar_score_core.dart';

/// Test-only: holds each draw for [delay] before running it on [inner],
/// reporting rising progress meanwhile and stopping at once when cancelled.
///
/// A draw of a few pilots finishes in milliseconds, too fast for an
/// end-to-end journey to look at its progress or press Cancel. The E2E builds
/// and the E2E test server use this runner; nothing else does.
class DelayedDrawRunner implements DrawRunner {
  const DelayedDrawRunner(
    this.inner, {
    this.delay = const Duration(seconds: 4),
  });

  final DrawRunner inner;
  final Duration delay;

  static const Duration _step = Duration(milliseconds: 100);

  @override
  Future<DrawResult> run(
    DrawSpec spec, {
    void Function(DrawProgress progress)? onProgress,
    DrawCancellation? cancellation,
  }) async {
    final cancelled = Completer<void>();
    cancellation?.onCancel(cancelled.complete);
    final steps = delay.inMilliseconds ~/ _step.inMilliseconds;
    for (var i = 0; i < steps; i++) {
      onProgress?.call(
        DrawProgress(percent: 90 * i ~/ steps, seed: 1, seedCount: 1),
      );
      await Future.any([Future<void>.delayed(_step), cancelled.future]);
      if (cancellation?.isCancelled ?? false) throw DrawCancelledError();
    }
    return inner.run(spec, onProgress: onProgress, cancellation: cancellation);
  }
}
