import 'dart:async';

import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../auth/auth_session.dart';
import '../services/sync/app_sync.dart';
import '../services/sync/no_app_sync.dart';
import '../services/ui_account/ui_account.dart';

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

  /// Which account UI-only state belongs to: the Local account offline, the
  /// signed-in account otherwise.
  UiAccount get uiAccount => const FixedUiAccount();

  /// What the screens may ask of synchronization; none on the web.
  AppSync get appSync => const NoAppSync();

  /// The preferences of the account in use (preferred time zone and locale),
  /// empty when none were chosen or they cannot be read. The native build
  /// reads the installation's own copy; the web build asks the service.
  Future<core.AccountPreferences> loadPreferences() async =>
      core.AccountPreferences();

  /// Fires when the account's preferences changed behind the app's back (the
  /// sign-in merged the account's with this installation's), so they should be
  /// read again.
  Stream<void> get preferencesChanged => const Stream<void>.empty();

  /// Stores the account's preferences. Throws when they cannot be saved (the
  /// web build is signed out, the service is unreachable); the default keeps
  /// nothing.
  Future<void> savePreferences(core.AccountPreferences preferences) async {}

  /// Whether this build keeps contests in a local database on the device, so
  /// the status bar shows the storage indicator. False on web.
  bool get hasLocalStorage => false;

  /// Reads something small from the local storage and throws when it cannot
  /// be read. Only called when [hasLocalStorage].
  Future<void> checkStorage() async {}

  /// Tells the platform that the remote API became reachable (or not).
  ///
  /// The native build uses it to resume synchronization; the web build has
  /// nothing to synchronize, so the default does nothing.
  void remoteReachabilityChanged({required bool reachable}) {}

  /// What synchronization finds out about the service: true when a sync
  /// reached it, false when it found no connection. Lets the connectivity
  /// monitor stop its health checks while syncs keep working.
  Stream<bool> get syncReachability => const Stream.empty();

  /// The director moved to [contestId]'s pages, or to pages outside any
  /// contest when it is null. Sets how often the service is asked for changes.
  void syncFocusChanged(String? contestId) {}

  /// The app went to the background ([active] false) or came back. Nothing is
  /// requested from the service in the background.
  void appActiveChanged({required bool active}) {}

  /// The Auth0 session behind [remoteApiClient]'s bearer token, or `null`
  /// when the bootstrap has no sign-in (tests).
  AuthSession? get authSession => null;

  /// Releases everything the bootstrap started. Idempotent — safe to call
  /// more than once (e.g. from both an app dispose and a process exit
  /// hook).
  Future<void> close();
}
