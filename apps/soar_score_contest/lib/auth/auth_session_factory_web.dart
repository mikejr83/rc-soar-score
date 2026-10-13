import 'auth0_web_session.dart';
import 'auth_config.dart';
import 'auth_session.dart';

/// The Auth0 session for this platform (web).
AuthSession createAuthSession() => Auth0WebSession(Auth0Config.web());
