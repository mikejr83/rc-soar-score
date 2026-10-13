import 'dart:io';

import 'auth0_windows_session.dart';
import 'auth_config.dart';
import 'auth_session.dart';
import 'url_scheme_registrar.dart';
import 'win32_registry_store.dart';

/// The Auth0 session for this platform (Windows). On Windows it registers the
/// callback URL scheme for the current user just before sign-in.
AuthSession createAuthSession() {
  final config = Auth0Config.windows();
  return Auth0WindowsSession(
    config,
    urlSchemeRegistrar: Platform.isWindows
        ? UrlSchemeRegistrar(
            store: const Win32RegistryStore(),
            scheme: config.windowsScheme,
            executablePath: Platform.resolvedExecutable,
          )
        : null,
  );
}
