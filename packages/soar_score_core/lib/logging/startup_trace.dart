import 'package:logging/logging.dart';

final _log = Logger('startup');

/// Diagnostic timing of the app's start (temporary, to find where a first run
/// spends its time). Every line reads `[+<ms since first use>] ...`.
abstract final class StartupTrace {
  static final Stopwatch _clock = Stopwatch()..start();

  static final List<String> _pending = [];
  static void Function(String line)? _sink;

  /// Also hands every line to [sink] (the native app writes a file, because a
  /// release build has no console). Lines logged before this is set are
  /// handed over first.
  static set sink(void Function(String line) sink) {
    _sink = sink;
    _pending.forEach(sink);
    _pending.clear();
  }

  static void mark(String message) {
    final line =
        '${DateTime.now().toUtc().toIso8601String()} '
        '[+${_clock.elapsedMilliseconds}ms] $message';
    _log.info('[+${_clock.elapsedMilliseconds}ms] $message');
    final sink = _sink;
    sink == null ? _pending.add(line) : sink(line);
  }

  /// Runs [body], logging when it begins and ends and how long it took.
  static Future<T> step<T>(String label, Future<T> Function() body) async {
    mark('begin $label');
    final watch = Stopwatch()..start();
    try {
      return await body();
    } finally {
      mark('end   $label (${watch.elapsedMilliseconds}ms)');
    }
  }
}
