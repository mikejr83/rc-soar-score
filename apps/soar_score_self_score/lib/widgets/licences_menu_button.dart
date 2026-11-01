import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../public_site.dart';

enum _Entry { openSource, inApp, privacy, terms }

/// The "More" menu in the app bar. It reaches the open source licences page
/// on the public site, the licence list built into the app, the Privacy
/// Policy and the Terms from every page.
class LicencesMenuButton extends StatelessWidget {
  const LicencesMenuButton({this.opener = openInBrowser, super.key});

  final UrlOpener opener;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_Entry>(
      tooltip: l10n.moreMenuTooltip,
      icon: const Icon(Icons.more_vert),
      onSelected: (entry) {
        switch (entry) {
          case _Entry.openSource:
            openOpenSourceLicences(context, opener: opener);
          case _Entry.inApp:
            showLicensePage(context: context);
          case _Entry.privacy:
            opener(privacyPageUri());
          case _Entry.terms:
            opener(termsPageUri());
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _Entry.openSource,
          child: Text(l10n.openSourceLicencesLink),
        ),
        PopupMenuItem(
          value: _Entry.inApp,
          child: Text(l10n.licencesInThisAppLink),
        ),
        PopupMenuItem(
          value: _Entry.privacy,
          child: Text(l10n.privacyPolicyLink),
        ),
        PopupMenuItem(value: _Entry.terms, child: Text(l10n.termsLink)),
      ],
    );
  }
}
