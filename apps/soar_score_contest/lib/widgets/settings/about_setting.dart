import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../public_site.dart';
import '../app_version_label.dart';

/// Opens [uri] in the browser, naming the page in a snackbar when it fails.
typedef ExternalLinkOpener = Future<bool> Function(Uri uri);

Future<bool> openInBrowser(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// The `About` card on the Settings page: the version, the open source
/// licences (online page and the copy bundled with the app, which works
/// offline), the source code location, and the Privacy Policy and Terms.
class AboutSetting extends StatelessWidget {
  const AboutSetting({super.key, this.opener = openInBrowser});

  /// Replaced in tests; the app opens the system browser.
  final ExternalLinkOpener opener;

  static const sourceCodeUrl = 'https://github.com/mikejr83/rc-soar-score';

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).aboutLinkFailed;
    var opened = false;
    try {
      opened = await opener(uri);
    } on Object {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.aboutHeading, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            const AppVersionLabel(),
            const SizedBox(height: 8),
            ListTile(
              key: const ValueKey('about-licences-online'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.open_in_new),
              title: Text(l10n.aboutOpenSourceLicences),
              subtitle: Text(l10n.aboutOpenSourceLicencesHint),
              onTap: () => _open(context, PublicSite.openSourceLicences),
            ),
            ListTile(
              key: const ValueKey('about-licences-bundled'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.article_outlined),
              title: Text(l10n.aboutLicencesOnThisDevice),
              subtitle: Text(l10n.aboutLicencesOnThisDeviceHint),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'RC Soar Score',
              ),
            ),
            ListTile(
              key: const ValueKey('about-source-code'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.code),
              title: Text(l10n.aboutSourceCode),
              subtitle: const Text(sourceCodeUrl),
              onTap: () => _open(context, Uri.parse(sourceCodeUrl)),
            ),
            ListTile(
              key: const ValueKey('about-privacy'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l10n.aboutPrivacyPolicy),
              onTap: () => _open(context, PublicSite.privacyPolicy),
            ),
            ListTile(
              key: const ValueKey('about-terms'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.gavel_outlined),
              title: Text(l10n.aboutTermsOfService),
              onTap: () => _open(context, PublicSite.termsOfService),
            ),
          ],
        ),
      ),
    );
  }
}
