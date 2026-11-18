import 'package:flutter/foundation.dart';

/// What the app is doing while it starts, which decides the splash message.
enum StartupMode {
  /// No local database exists yet: the first run builds it.
  initializing,

  /// The database exists at the current version.
  starting,

  /// The database is on an older version and is being upgraded.
  updating,
}

/// Decides the [StartupMode] from the stored schema version.
///
/// [storedVersion] is `null` when there is no database yet.
StartupMode startupModeFor({
  required int? storedVersion,
  required int currentVersion,
}) {
  if (storedVersion == null) return StartupMode.initializing;
  if (storedVersion < currentVersion) return StartupMode.updating;
  return StartupMode.starting;
}

/// How long the splash stays up at least, so its message can be read.
const Duration minimumSplashDuration = Duration(seconds: 5);

/// What the splash shows, decided before the database opens.
class StartupPlan {
  const StartupPlan(this.mode);

  final StartupMode mode;
}

/// Name of the environment variable (and `--dart-define`) that switches the
/// splash off for debugging: `SOAR_SCORE_NO_SPLASH=1` (any non-empty value
/// but `0` or `false`) in the environment, or
/// `--dart-define=SOAR_SCORE_NO_SPLASH=true`.
const String noSplashVariable = 'SOAR_SCORE_NO_SPLASH';

/// Whether the environment variable [value] turns the splash off.
bool noSplashRequested(String? value) {
  final v = value?.trim().toLowerCase();
  return v != null && v.isNotEmpty && v != '0' && v != 'false';
}

/// Whether this build skips the splash: the demo-database and E2E builds
/// (`SOAR_SCORE_DEMO` or `SOAR_SCORE_E2E`, never in a release build), so the
/// journeys start at once, or a build with `SOAR_SCORE_NO_SPLASH=true`.
const bool splashSuppressedByBuild =
    bool.fromEnvironment(noSplashVariable) ||
    (!kReleaseMode &&
        (bool.fromEnvironment('SOAR_SCORE_DEMO') ||
            bool.fromEnvironment('SOAR_SCORE_E2E')));
