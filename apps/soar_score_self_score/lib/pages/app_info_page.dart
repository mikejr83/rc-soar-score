import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../public_site.dart';
import '../router.dart';

/// Application info: the open source licences, the licences built into the
/// app, the Privacy Policy and the Terms in one place.
class AppInfoPage extends StatelessWidget {
  const AppInfoPage({this.opener = openInBrowser, super.key});

  final UrlOpener opener;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.backLabel,
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(homePath),
        ),
        title: Text(l10n.appInfoTitle),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              ListTile(
                title: Text(l10n.openSourceLicencesLink),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => openOpenSourceLicences(context, opener: opener),
              ),
              ListTile(
                title: Text(l10n.licencesInThisAppLink),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showAppLicences(context),
              ),
              ListTile(
                title: Text(l10n.privacyPolicyLink),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => openLinkOrExplain(
                  context,
                  privacyPageUri(),
                  opener: opener,
                ),
              ),
              ListTile(
                title: Text(l10n.termsLink),
                trailing: const Icon(Icons.open_in_new),
                onTap: () =>
                    openLinkOrExplain(context, termsPageUri(), opener: opener),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
