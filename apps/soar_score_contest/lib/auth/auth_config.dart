/// Auth0 tenant settings for the contest app.
///
/// Every value is a public identifier (a SPA or native app has no client
/// secret), so the defaults point at the development tenant and are committed.
/// A release build overrides them with `--dart-define`, for example
/// `--dart-define=AUTH0_DOMAIN=<production tenant>`.
class Auth0Config {
  const Auth0Config({
    required this.domain,
    required this.clientId,
    required this.audience,
    required this.windowsScheme,
  });

  /// Development tenant. The region part of the domain (`us`) is an
  /// assumption; confirm it on the tenant's Settings page and override with
  /// `AUTH0_DOMAIN` when it differs.
  static const String defaultDomain = 'dev-2qpi7354ddlhe45g.us.auth0.com';

  /// Client ID of the Auth0 application the web build signs in with.
  static const String defaultWebClientId = 'ALL8oKywE1J31NEKvcaypfSeZSsoDXII';

  /// Client ID of the Auth0 application the Windows build signs in with.
  static const String defaultWindowsClientId =
      '3FdIOOxNr4DF4iT8BDaqKWc9NabpEKbz';

  /// Identifier of the API the access token is requested for. The server
  /// checks it against its `API_AUDIENCE` setting.
  static const String defaultAudience = 'https://soar-score.com/server';

  /// Custom URL scheme the Windows build registers with the operating system.
  /// The Auth0 application's callback and logout URL is
  /// `<scheme>://callback`. It is not a build setting: the runner's
  /// `windows/runner/main.cpp` repeats it in C++ (mutex, pipe and callback
  /// prefix), so changing it means changing both files and the installer.
  static const String defaultWindowsScheme = 'com.soarscore.contest';

  /// Fixed loopback port of the sign-in callback listener (the intermediary
  /// server of `auth0_flutter`). Auth0 only accepts exact callback URLs, so it
  /// cannot be an OS-assigned port. Changing it means changing the Auth0
  /// application's callback and logout URLs too.
  static const int windowsCallbackPort = 47821;

  /// The configuration for the web build.
  factory Auth0Config.web() => const Auth0Config(
    domain: String.fromEnvironment('AUTH0_DOMAIN', defaultValue: defaultDomain),
    clientId: String.fromEnvironment(
      'AUTH0_WEB_CLIENT_ID',
      defaultValue: defaultWebClientId,
    ),
    audience: String.fromEnvironment(
      'AUTH0_AUDIENCE',
      defaultValue: defaultAudience,
    ),
    windowsScheme: defaultWindowsScheme,
  );

  /// The configuration for the Windows build.
  factory Auth0Config.windows() => const Auth0Config(
    domain: String.fromEnvironment('AUTH0_DOMAIN', defaultValue: defaultDomain),
    clientId: String.fromEnvironment(
      'AUTH0_WINDOWS_CLIENT_ID',
      defaultValue: defaultWindowsClientId,
    ),
    audience: String.fromEnvironment(
      'AUTH0_AUDIENCE',
      defaultValue: defaultAudience,
    ),
    windowsScheme: defaultWindowsScheme,
  );

  /// Tenant domain without a scheme, for example `tenant.us.auth0.com`.
  final String domain;

  final String clientId;

  /// API identifier the access token is issued for.
  final String audience;

  final String windowsScheme;

  /// The custom-scheme URL the local listener hands the callback to, which
  /// Windows delivers to the running app.
  String get windowsCallbackUrl => '$windowsScheme://callback';

  /// The page Auth0 redirects the Windows browser to after sign-in. The
  /// local listener shows a message there and forwards to
  /// [windowsCallbackUrl].
  String get windowsRedirectUrl =>
      'http://localhost:$windowsCallbackPort/callback';

  /// The page Auth0 sends the Windows browser to after sign-out.
  String get windowsLogoutReturnUrl =>
      'http://localhost:$windowsCallbackPort/logout';

  /// Scopes requested at sign-in. `offline_access` yields a refresh token.
  static const Set<String> scopes = {
    'openid',
    'profile',
    'email',
    'offline_access',
  };
}
