/// Auth0 settings of the self-scoring app (a Single Page Web Application).
///
/// Every value is a public identifier (a SPA has no client secret), so the
/// defaults point at the development tenant and are committed. A release
/// build overrides them with `--dart-define`, for example
/// `--dart-define=AUTH0_DOMAIN=<production tenant>`. See
/// `docs/auth0-setup.md`.
class Auth0Config {
  const Auth0Config({
    required this.domain,
    required this.clientId,
    required this.audience,
  });

  /// Tenant domain without a scheme (the custom login domain).
  static const String defaultDomain = 'login.rcsoarscore.com';

  /// Client ID of the Auth0 application this app signs in with (not the
  /// contest app's).
  static const String defaultClientId = 'nDbIIguVqm9rgpebKX3HuThfrhGKnRFT';

  /// Identifier of the API the access token is requested for; the server
  /// checks it against its `API_AUDIENCE`.
  static const String defaultAudience = 'https://soar-score.com/server';

  factory Auth0Config.fromEnvironment() => const Auth0Config(
    domain: String.fromEnvironment('AUTH0_DOMAIN', defaultValue: defaultDomain),
    clientId: String.fromEnvironment(
      'AUTH0_SELF_SCORE_CLIENT_ID',
      defaultValue: defaultClientId,
    ),
    audience: String.fromEnvironment(
      'AUTH0_AUDIENCE',
      defaultValue: defaultAudience,
    ),
  );

  final String domain;
  final String clientId;
  final String audience;

  /// Scopes requested at sign-in. `offline_access` yields a refresh token.
  static const Set<String> scopes = {
    'openid',
    'profile',
    'email',
    'offline_access',
  };
}
