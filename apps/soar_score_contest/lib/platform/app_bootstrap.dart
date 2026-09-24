import 'package:soar_score_api/soar_score_api.dart';

/// Shared view of the platform bootstrap performed before the app's first
/// frame: the `ApiClient` every screen talks through, and the resources that
/// `close()` releases on shutdown.
///
/// The web and native implementations (`bootstrap.dart` and
/// `bootstrap_web.dart`) are selected at compile time by `main.dart`'s
/// conditional import. On native desktop the bootstrap also hosts the
/// embedded API server (ticket 018) and therefore owns its lifecycle; on
/// the web it holds only the client pointed at the deployed API.
abstract class AppBootstrap {
  const AppBootstrap();

  /// The API client every part of the app talks through.
  ApiClient get apiClient;

  /// Releases everything the bootstrap started. Idempotent — safe to call
  /// more than once (e.g. from both an app dispose and a process exit
  /// hook).
  Future<void> close();
}
