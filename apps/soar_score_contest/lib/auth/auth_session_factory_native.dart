import 'auth0_windows_session.dart';
import 'auth_config.dart';
import 'auth_session.dart';

/// The Auth0 session for this platform (Windows).
AuthSession createAuthSession() => Auth0WindowsSession(Auth0Config.windows());
