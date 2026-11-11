import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

/// `--dart-define=E2E_STOP_AFTER=<phase number>` (or the `E2E_STOP_AFTER`
/// environment variable of `scripts/e2e-contest.sh` / `e2e-contest.ps1`) ends the journey
/// after that phase, so work on one phase does not wait for the later ones.
const String _apiBase = String.fromEnvironment('SOAR_SCORE_API_BASE_URL');

const String _stopAfterDefine = String.fromEnvironment('E2E_STOP_AFTER');

/// `--dart-define=E2E_SCREENSHOTS=steps` (pass it after `--` to the scripts)
/// saves a web screenshot after every step, to see how far a run that hangs
/// or is stopped by the timeout got.
const bool _screenshotEachStep =
    String.fromEnvironment('E2E_SCREENSHOTS') == 'steps';

/// A person the journey creates.
typedef Person = ({String first, String last, String email});

/// Names and values the phases share. Everything the journey creates is named
/// "E2E ..." or uses an `@e2e.example` address, so finders never match demo
/// rows, and nothing here depends on how the matrix draw came out.
class JourneyContext {
  /// The contest the whole journey runs.
  final String contestName = 'E2E Open 2026';

  /// People added in the participants manager (phase 2). The first
  /// [rosterPilots] of them fly in [contestName].
  final List<Person> roster = const [
    (first: 'Zoe', last: 'Whitfield', email: 'zoe.whitfield@e2e.example'),
    (first: 'Milo', last: 'Okafor', email: 'milo.okafor@e2e.example'),
    (first: 'Nadia', last: 'Petrov', email: 'nadia.petrov@e2e.example'),
    (first: 'Owen', last: 'Quinn', email: 'owen.quinn@e2e.example'),
    (first: 'Priya', last: 'Raman', email: 'priya.raman@e2e.example'),
    (first: 'Quentin', last: 'Shaw', email: 'quentin.shaw@e2e.example'),
    (first: 'Rosa', last: 'Tanaka', email: 'rosa.tanaka@e2e.example'),
    (first: 'Sam', last: 'Underhill', email: 'sam.underhill@e2e.example'),
  ];

  /// How many of [roster] fly in [contestName].
  final int rosterPilots = 6;

  /// Existing demo people who also fly in [contestName].
  final List<String> demoPilots = const ['Avery Brooks', 'Blake Castillo'];

  /// The person created inside the wizard's participants step.
  final Person wizardPerson = (
    first: 'Tess',
    last: 'Valdez',
    email: 'tess.valdez@e2e.example',
  );

  /// The full names of everyone who flies in [contestName].
  List<String> get pilotNames => [
    for (final p in roster.take(rosterPilots)) '${p.first} ${p.last}',
    ...demoPilots,
    '${wizardPerson.first} ${wizardPerson.last}',
  ];

  /// Groups per round and preliminary rounds chosen in the wizard.
  final int groupsPerRound = 2;
  final int rounds = 3;
}

/// Runs a journey as numbered phases and steps and tells where it failed.
///
/// A step starts from a known place (it calls `goToMainPage`, `openContest`
/// and the like itself) and never relies on where the previous step left the
/// screen; the steps inside one wizard run are the exception, because the
/// wizard is a single flow. On failure the error names the step, the route,
/// the texts on screen and the steps that ran before it. The web `flutter
/// drive` run is quiet until it ends, so that report, not the live log, is
/// what to read there.
class Journey {
  Journey(this.tester, this.binding);

  final WidgetTester tester;
  final IntegrationTestWidgetsFlutterBinding binding;

  final List<String> _log = [];
  final Stopwatch _clock = Stopwatch()..start();
  final int? _stopAfter = int.tryParse(_stopAfterDefine);
  bool _stopped = false;
  int _phase = 0;
  int _stepInPhase = 0;

  /// The log so far, one line per phase and step.
  List<String> get log => List.unmodifiable(_log);

  /// Runs [body] as phase [number] unless an earlier phase ended the run
  /// (`E2E_STOP_AFTER`).
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
    if (_stopAfter != null && number >= _stopAfter) {
      _stopped = true;
    }
  }

  /// Runs [body] as the next step of the phase, logging platform skips.
  Future<void> step(
    String title,
    Future<void> Function() body, {
    bool nativeOnly = false,
    bool webOnly = false,
    Duration timeout = const Duration(minutes: 4),
  }) async {
    final id = '$_phase.${++_stepInPhase}';
    if (nativeOnly && kIsWeb) {
      _note('  $id $title: SKIPPED (native only)');
      return;
    }
    if (webOnly && !kIsWeb) {
      _note('  $id $title: SKIPPED (web only)');
      return;
    }
    final started = _clock.elapsed;
    _note('  $id $title ...');
    try {
      // A step that hangs (an await that never completes) would otherwise
      // run into the whole file's timeout and say nothing about where.
      // The timeout only reports the step; it does not cancel `body`, which may
      // still touch the app while the failure is reported, so treat it as a
      // diagnostic for a hung run, not as a way to stop work.
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
        ..writeln('  on screen: ${_screenTexts()}')
        ..writeln('Steps so far:')
        ..writeAll(_log.map((line) => '  $line\n'));
      unawaited(_remote(report.toString().replaceAll('\n', ' | ')));
      await _screenshot('failed-step-$id');
      Error.throwWithStackTrace(TestFailure(report.toString()), stack);
    }
    if (_screenshotEachStep) {
      await _screenshot('step-$id');
    }
    final took = (_clock.elapsed - started).inSeconds;
    _log[_log.length - 1] = '  $id $title: ok (${took}s)';
    debugPrint('[E2E] ${_log.last}');
    unawaited(_remote(_log.last));
  }

  /// Prints the whole log and hands it to the web driver, which writes it to
  /// `build/integration_response_data.json` (a web run shows nothing live);
  /// call at the end of the journey.
  void finish() {
    binding.reportData = {'journey': _log, 'seconds': _clock.elapsed.inSeconds};
    debugPrint('[E2E] done in ${_clock.elapsed.inSeconds}s');
    for (final line in _log) {
      debugPrint('[E2E] $line');
    }
  }

  void _note(String line) {
    _log.add(line);
    debugPrint('[E2E] $line');
    unawaited(_remote(line));
  }

  /// Sends [line] to the web E2E server's log (`POST /__e2e/log`), which the
  /// scripts echo while the run is going. Best effort; native runs print live.
  Future<void> _remote(String line) async {
    if (_apiBase.isEmpty) {
      return;
    }
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

  List<String> _screenTexts() => find
      .byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .whereType<String>()
      .take(40)
      .toList();

  /// Saves a screenshot through the web driver (`test_driver/`); other
  /// targets rely on the text dump above.
  Future<void> _screenshot(String name) async {
    if (!kIsWeb) {
      return;
    }
    try {
      await binding.takeScreenshot(name).timeout(const Duration(seconds: 15));
    } catch (_) {
      // The screenshot is a diagnostic only; never hide the real failure.
    }
  }
}
