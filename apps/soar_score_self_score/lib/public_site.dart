import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Base URL of the public project site. Builds can point it elsewhere with
/// `--dart-define=SOAR_SCORE_PUBLIC_SITE_URL=...`.
const String publicSiteBaseUrl = String.fromEnvironment(
  'SOAR_SCORE_PUBLIC_SITE_URL',
  defaultValue: 'https://rcsoarscore.com',
);

/// The public site page that lists open source notices for this app.
Uri openSourcePageUri({String base = publicSiteBaseUrl}) =>
    _page(base, '/open-source', fragment: 'self-scoring');

Uri privacyPageUri({String base = publicSiteBaseUrl}) =>
    _page(base, '/privacy');

Uri termsPageUri({String base = publicSiteBaseUrl}) => _page(base, '/terms');

Uri _page(String base, String path, {String? fragment}) {
  final root = Uri.parse(base);
  return root.replace(path: path, fragment: fragment);
}

/// Opens [uri] in a new tab. Returns false when it could not be opened.
typedef UrlOpener = Future<bool> Function(Uri uri);

Future<bool> openInBrowser(Uri uri) async {
  try {
    return await launchUrl(uri, webOnlyWindowName: '_blank');
  } catch (_) {
    return false;
  }
}

/// Opens the open source licences page on the public site. When the site
/// cannot be opened, shows the licence list built into the app instead.
Future<void> openOpenSourceLicences(
  BuildContext context, {
  UrlOpener opener = openInBrowser,
}) async {
  final opened = await opener(openSourcePageUri());
  if (!opened && context.mounted) {
    showLicensePage(context: context);
  }
}
