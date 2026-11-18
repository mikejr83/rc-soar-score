import 'startup_mode.dart';

/// Runs [start] and, when [plan] says the splash is on, shows it through
/// [showSplash] first and keeps it up for at least [minimum].
///
/// A failure of [start] is thrown at once, without waiting out [minimum], so
/// the failure page appears immediately.
///
/// Only the first start shows the splash: a retry from the failure page calls
/// [start] directly, so the failure page stays mounted and can show the next
/// error.
Future<T> startWithSplash<T>({
  required Future<StartupPlan?> Function() plan,
  required Future<T> Function() start,
  required void Function(StartupMode mode) showSplash,
  Duration minimum = minimumSplashDuration,
}) async {
  final chosen = await plan();
  if (chosen == null) return start();
  showSplash(chosen.mode);
  final wait = Future<void>.delayed(minimum);
  final started = await start();
  await wait;
  return started;
}
