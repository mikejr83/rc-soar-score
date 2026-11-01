/// Where the public site lives, for links out of the app.
///
/// Builds can point at another host (a preview deployment, for example) with
/// `--dart-define=SOAR_SCORE_PUBLIC_SITE_URL=https://example.test`.
class PublicSite {
  const PublicSite._();

  static const String baseUrl = String.fromEnvironment(
    'SOAR_SCORE_PUBLIC_SITE_URL',
    defaultValue: 'https://rcsoarscore.com',
  );

  static Uri _at(String path) => Uri.parse('$baseUrl$path');

  /// The contest app's section of the open source licences page.
  static Uri get openSourceLicences => _at('/open-source#contest-app');

  static Uri get privacyPolicy => _at('/privacy');

  static Uri get termsOfService => _at('/terms');
}
