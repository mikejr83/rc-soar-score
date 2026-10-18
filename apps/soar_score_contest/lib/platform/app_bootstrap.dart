import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../auth/auth_session.dart';
import '../services/sync/app_sync.dart';
import '../services/sync/no_app_sync.dart';

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

  ApiClient get remoteApiClient;

  /// Where UI-only state (theme, hidden panels, drafts) is kept, or `null`
  /// when the bootstrap has none (tests).
  LocalUiStore? get localUiStore => null;

  /// What the screens may ask of synchronization; none on the web.
  AppSync get appSync => const NoAppSync();

  /// Tells the platform that the remote API became reachable (or not).
  ///
  /// The native build uses it to resume synchronization; the web build has
  /// nothing to synchronize, so the default does nothing.
  void remoteReachabilityChanged({required bool reachable}) {}

  /// The Auth0 session behind [remoteApiClient]'s bearer token, or `null`
  /// when the bootstrap has no sign-in (tests).
  AuthSession? get authSession => null;

  /// Releases everything the bootstrap started. Idempotent — safe to call
  /// more than once (e.g. from both an app dispose and a process exit
  /// hook).
  Future<void> close();
}
