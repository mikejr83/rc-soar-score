import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

import '../support/launch_app.dart';

const String _apiBase = String.fromEnvironment('SOAR_SCORE_API_BASE_URL');

/// `--dart-define=E2E_STOP_AFTER=<phase number>` (or the `E2E_STOP_AFTER`
/// environment variable of `scripts/e2e-score.sh`) ends the journey after
/// that phase.
const String _stopAfterDefine = String.fromEnvironment('E2E_STOP_AFTER');

/// `--dart-define=E2E_SCREENSHOTS=steps` saves a screenshot after every step.
const bool _screenshotEachStep =
    String.fromEnvironment('E2E_SCREENSHOTS') == 'steps';

/// Runs a journey as numbered phases and steps and tells where it failed.
///
/// A step starts from a known place and never relies on where the previous
/// step left the screen. On failure the error names the step, the route, the
/// texts on screen and the steps that ran before it. The steps are also
/// posted to the E2E server (`POST /__e2e/log`), whose `[E2E]` lines the
/// script echoes live.
class Journey {
  Journey(this.tester, this.binding) {
    // The framework fails a test that logged errors but, on the web, shows
    // only their count. Send each one to the server's log as well.
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      unawaited(
        _remote(
          'FlutterError: ${details.exceptionAsString()} '
                  '${(details.stack?.toString() ?? '').split('\n').take(6).join(' | ')}'
              .replaceAll('\n', ' '),
        ),
      );
      previous?.call(details);
    };
  }

  final WidgetTester tester;
  final IntegrationTestWidgetsFlutterBinding binding;

  final List<String> _log = [];
  final Stopwatch _clock = Stopwatch()..start();
  final int? _stopAfter = int.tryParse(_stopAfterDefine);
  bool _stopped = false;
  int _phase = 0;
  int _stepInPhase = 0;

  Future<void> phase(
    int number,
    String title,
    Future<void> Function() body,
  ) async {
    if (_stopped) {
      _note('PHASE $number $title: not run (E2E_STOP_AFTER=$_stopAfterDefine)');
      return;
    }
    _phase = number;
    _stepInPhase = 0;
    _note('PHASE $number $title');
    await body();
    if (_stopAfter != null && number >= _stopAfter) _stopped = true;
  }

  Future<void> step(
    String title,
    Future<void> Function() body, {
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final id = '$_phase.${++_stepInPhase}';
    final started = _clock.elapsed;
    _note('  $id $title ...');
    try {
      // The timeout only reports the step; it does not cancel `body`.
      await body().timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'step took longer than ${timeout.inSeconds}s',
        ),
      );
    } catch (error, stack) {
      final report = StringBuffer()
        ..writeln('Journey failed at step $id "$title"')
        ..writeln('  after ${_clock.elapsed.inSeconds}s, route ${_route()}')
        ..writeln('  error: $error')
        ..writeln('  on screen: ${screenTexts()}')
        ..writeln('Steps so far:')
        ..writeAll(_log.map((line) => '  $line\n'));
      unawaited(_remote(report.toString().replaceAll('\n', ' | ')));
      await _screenshot('failed-step-$id');
      Error.throwWithStackTrace(TestFailure(report.toString()), stack);
    }
    if (_screenshotEachStep) await _screenshot('step-$id');
    final took = (_clock.elapsed - started).inSeconds;
    _log[_log.length - 1] = '  $id $title: ok (${took}s)';
    debugPrint('[E2E] ${_log.last}');
    unawaited(_remote(_log.last));
  }

  /// Hands the log to the web driver (`build/integration_response_data.json`).
  void finish() {
    binding.reportData = {'journey': _log, 'seconds': _clock.elapsed.inSeconds};
    debugPrint('[E2E] done in ${_clock.elapsed.inSeconds}s');
  }

  void _note(String line) {
    _log.add(line);
    debugPrint('[E2E] $line');
    unawaited(_remote(line));
  }

  Future<void> _remote(String line) async {
    if (_apiBase.isEmpty) return;
    try {
      await http
          .post(Uri.parse('$_apiBase/__e2e/log'), body: line)
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  String _route() {
    try {
      final context = tester.element(find.byType(Scaffold).first);
      return GoRouter.of(context).routeInformationProvider.value.uri.toString();
    } catch (_) {
      return '(unknown)';
    }
  }

  Future<void> _screenshot(String name) async {
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
  }
}
