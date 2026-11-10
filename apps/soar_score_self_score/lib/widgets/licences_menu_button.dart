import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../public_site.dart';

enum _Entry { copyInvitation, openSource, inApp, privacy, terms }

/// The "More" menu in the app bar. It reaches the open source licences page
/// on the public site, the licence list built into the app, the Privacy
/// Policy and the Terms from every page.
class LicencesMenuButton extends StatelessWidget {
  const LicencesMenuButton({
    this.opener = openInBrowser,
    this.onCopyInvitationLink,
    super.key,
  });

  final UrlOpener opener;

  /// When set, the menu leads with "Copy invitation link".
  final VoidCallback? onCopyInvitationLink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_Entry>(
      tooltip: l10n.moreMenuTooltip,
      icon: const Icon(Icons.more_vert),
      onSelected: (entry) {
        switch (entry) {
          case _Entry.copyInvitation:
            onCopyInvitationLink?.call();
          case _Entry.openSource:
            openOpenSourceLicences(context, opener: opener);
          case _Entry.inApp:
            showAppLicences(context);
          case _Entry.privacy:
            openLinkOrExplain(context, privacyPageUri(), opener: opener);
          case _Entry.terms:
            openLinkOrExplain(context, termsPageUri(), opener: opener);
        }
      },
      itemBuilder: (context) => [
        if (onCopyInvitationLink != null)
          PopupMenuItem(
            value: _Entry.copyInvitation,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link),
              title: Text(l10n.copyInvitationLink),
            ),
          ),
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
