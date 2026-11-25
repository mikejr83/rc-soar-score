import 'auth_session.dart';

/// No sign-in outside the browser: the app is web-only.
AuthSession createAuthSession() => UnavailableAuthSession();
