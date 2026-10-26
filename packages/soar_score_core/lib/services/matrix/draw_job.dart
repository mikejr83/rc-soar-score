import '../../enums/lane_mode.dart';
import '../../errors/contest_state_error.dart';
import '../../models/id.dart';
import 'basic_draw.dart';
import 'draw_engine.dart';
import 'draw_optimizer.dart';

/// How far a draw has come: [percent] (0 to 99; a finished draw has no
/// progress, it has its matrix) and which of the [seedCount] seeds is being
/// improved, counting from 1.
class DrawProgress {
  const DrawProgress({
    required this.percent,
    required this.seed,
    required this.seedCount,
  });

  static const DrawProgress none = DrawProgress(
    percent: 0,
    seed: 1,
    seedCount: 1,
  );

  final int percent;
  final int seed;
  final int seedCount;
}

/// The draw was cancelled before it finished. Nothing was stored, so the
/// prior matrix is as it was.
class DrawCancelledError extends ContestStateError {
  DrawCancelledError()
    : super('draw_cancelled', 'the draw was cancelled; nothing was changed');
}

/// A request to stop a running draw.
class DrawCancellation {
  bool _cancelled = false;
  final List<void Function()> _listeners = [];

  bool get isCancelled => _cancelled;

  /// Cancels once; later calls do nothing.
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Calls [listener] when the draw is cancelled (at once if it already
  /// was).
  void onCancel(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }
}

/// Everything [DrawEngine.generate] needs, as plain data, so a draw can be
/// handed to another isolate and run there.
class DrawSpec {
  const DrawSpec({
    required this.pilots,
    required this.rounds,
    required this.groupsPerRound,
    required this.teamProtection,
    required this.laneMode,
    required this.seed,
    required this.seedCount,
    required this.attemptsPerRound,
    this.history = const [],
  });

  final List<DrawPilot> pilots;
  final int rounds;
  final int groupsPerRound;
  final bool teamProtection;
  final LaneMode laneMode;
  final int seed;
  final int seedCount;
  final int attemptsPerRound;
  final List<List<List<DrawSlot>>> history;

  /// Draws it here and now, on the calling isolate.
  DrawResult generate({void Function(DrawProgress progress)? onProgress}) =>
      const DrawEngine().generate(
        pilots: pilots,
        rounds: rounds,
        groupsPerRound: groupsPerRound,
        teamProtection: teamProtection,
        laneMode: laneMode,
        seed: seed,
        seedCount: seedCount,
        attemptsPerRound: attemptsPerRound,
        iterationsPerPlacement: DrawOptimizer.defaultIterationsPerPlacement,
        history: history,
        onProgress: onProgress,
      );
}

/// Where a draw runs. The result is the same wherever it runs: the draw
/// depends on the [DrawSpec] alone.
abstract interface class DrawRunner {
  /// Runs [spec], telling [onProgress] how far it has come. When
  /// [cancellation] is cancelled the run stops and the future fails with a
  /// [DrawCancelledError].
  Future<DrawResult> run(
    DrawSpec spec, {
    void Function(DrawProgress progress)? onProgress,
    DrawCancellation? cancellation,
  });
}

/// Runs the draw on the calling isolate. It cannot be stopped once started,
/// and it blocks that isolate until done; the API server uses a runner on
/// another isolate instead. Used by tests and wherever isolates do not
/// exist.
class InProcessDrawRunner implements DrawRunner {
  const InProcessDrawRunner();

  @override
  Future<DrawResult> run(
    DrawSpec spec, {
    void Function(DrawProgress progress)? onProgress,
    DrawCancellation? cancellation,
  }) async {
    if (cancellation?.isCancelled ?? false) throw DrawCancelledError();
    final result = spec.generate(onProgress: onProgress);
    if (cancellation?.isCancelled ?? false) throw DrawCancelledError();
    return result;
  }
}

enum DrawJobState { running, completed, cancelled, failed }

/// What a draw is doing now.
class DrawJobStatus {
  const DrawJobStatus(this.id, this.state, this.progress);

  final Id id;
  final DrawJobState state;
  final DrawProgress progress;
}

/// The draws this server is running or ran lately, by the id of the matrix
/// revision they make, so a client can ask how far one has come or cancel
/// it.
class DrawJobs {
  DrawJobs({this.keep = 50});

  /// How many finished draws are remembered.
  final int keep;

  final Map<Id, _Job> _jobs = {};

  /// The status of draw [id], or `null` when it is not known.
  DrawJobStatus? status(Id id) => _jobs[id]?.status;

  /// Cancels draw [id] if it is still being drawn and returns its status
  /// (`null` when unknown). A draw that has finished is not changed.
  DrawJobStatus? cancel(Id id) {
    final job = _jobs[id];
    if (job == null) return null;
    if (job.state == DrawJobState.running) job.cancellation.cancel();
    return job.status;
  }

  /// Runs [spec] on [runner] as draw [id]. Fails with a
  /// [DrawCancelledError] when cancelled, and with a [ContestStateError]
  /// (`draw_running`) when [id] is already being drawn.
  Future<DrawResult> run(Id id, DrawRunner runner, DrawSpec spec) async {
    if (_jobs[id]?.state == DrawJobState.running) {
      throw ContestStateError(
        'draw_running',
        'this draw is already running; wait for it to finish',
      );
    }
    _jobs.remove(id);
    final job = _jobs[id] = _Job(id);
    try {
      final result = await runner.run(
        spec,
        onProgress: (progress) => job.progress = progress,
        cancellation: job.cancellation,
      );
      job.state = DrawJobState.completed;
      return result;
    } on DrawCancelledError {
      job.state = DrawJobState.cancelled;
      rethrow;
    } catch (_) {
      job.state = DrawJobState.failed;
      rethrow;
    } finally {
      _trim();
    }
  }

  /// Forgets the oldest finished draws beyond [keep].
  void _trim() {
    final finished = [
      for (final entry in _jobs.entries)
        if (entry.value.state != DrawJobState.running) entry.key,
    ];
    for (var i = 0; i < finished.length - keep; i++) {
      _jobs.remove(finished[i]);
    }
  }
}

class _Job {
  _Job(this.id);

  final Id id;
  final DrawCancellation cancellation = DrawCancellation();
  DrawJobState state = DrawJobState.running;
  DrawProgress progress = DrawProgress.none;

  DrawJobStatus get status => DrawJobStatus(id, state, progress);
}
