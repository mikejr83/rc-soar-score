import 'dart:io';

import '../server/auth_callback_server.dart';
import 'auth0_windows_session.dart';
import 'auth_config.dart';
import 'auth_session.dart';
import 'e2e_mode.dart';
import 'e2e_signed_out_session.dart';
import 'url_scheme_registrar.dart';
import 'win32_registry_store.dart';

/// The Auth0 session for this platform (Windows). On Windows it registers the
/// callback URL scheme for the current user just before sign-in.
AuthSession createAuthSession() {
  if (e2eSignedOutMode) {
    return E2eSignedOutSession();
  }
  final config = Auth0Config.windows();
  return Auth0WindowsSession(
    config,
    callbackListener: AuthCallbackServer(
      port: Auth0Config.windowsCallbackPort,
      appScheme: config.windowsScheme,
    ),
    urlSchemeRegistrar: Platform.isWindows
        ? UrlSchemeRegistrar(
            store: const Win32RegistryStore(),
            scheme: config.windowsScheme,
            executablePath: Platform.resolvedExecutable,
          )
        : null,
  );
}
