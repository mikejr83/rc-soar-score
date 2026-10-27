import 'dart:async';
import 'dart:isolate';

import 'package:soar_score_core/soar_score_core.dart';

/// Runs each draw on an isolate of its own, so the isolate that serves the
/// API (the app's UI isolate in the embedded server) keeps answering while the
/// optimizer works, and a cancelled draw is stopped by ending its isolate.
///
/// The draw is the one [DrawSpec.generate] makes anywhere: the seed alone
/// decides it, so the result matches an in-process run exactly.
class IsolateDrawRunner implements DrawRunner {
  const IsolateDrawRunner();

  @override
  Future<DrawResult> run(
    DrawSpec spec, {
    void Function(DrawProgress progress)? onProgress,
    DrawCancellation? cancellation,
  }) async {
    if (cancellation?.isCancelled ?? false) throw DrawCancelledError();

    final messages = ReceivePort();
    final exits = ReceivePort();
    final done = Completer<DrawResult>();
    final isolate = await Isolate.spawn(
      _draw,
      _Start(messages.sendPort, spec),
      onExit: exits.sendPort,
    );

    messages.listen((message) {
      if (done.isCompleted) return;
      switch (message) {
        case DrawProgress():
          onProgress?.call(message);
        case DrawResult():
          done.complete(message);
        case _Failed():
          done.completeError(message.error());
      }
    });
    exits.listen((_) {
      if (!done.isCompleted) {
        done.completeError(StateError('the draw stopped unexpectedly'));
      }
    });
    cancellation?.onCancel(() {
      isolate.kill(priority: Isolate.immediate);
      if (!done.isCompleted) done.completeError(DrawCancelledError());
    });

    try {
      return await done.future;
    } finally {
      isolate.kill(priority: Isolate.immediate);
      messages.close();
      exits.close();
    }
  }
}

class _Start {
  const _Start(this.port, this.spec);

  final SendPort port;
  final DrawSpec spec;
}

/// A failure of the draw, in a form that crosses isolates.
class _Failed {
  const _Failed(this.invalid, this.message);

  /// Whether the settings could not be met (an [ArgumentError]).
  final bool invalid;
  final String message;

  Object error() => invalid ? ArgumentError(message) : StateError(message);
}

void _draw(_Start start) {
  try {
    start.port.send(start.spec.generate(onProgress: start.port.send));
  } on ArgumentError catch (error) {
    start.port.send(_Failed(true, '${error.message ?? error}'));
  } on Object catch (error) {
    start.port.send(_Failed(false, '$error'));
  }
}
