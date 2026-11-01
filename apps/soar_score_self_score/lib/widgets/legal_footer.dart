import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../public_site.dart';

/// Footer links for pages without an app bar, such as the landing page where
/// pilots sign in or sign up: licences, Privacy Policy and Terms.
class LegalFooter extends StatelessWidget {
  const LegalFooter({this.opener = openInBrowser, super.key});

  final UrlOpener opener;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        TextButton(
          onPressed: () => openOpenSourceLicences(context, opener: opener),
          child: Text(l10n.openSourceLicencesLink),
        ),
        TextButton(
          onPressed: () =>
              openLinkOrExplain(context, privacyPageUri(), opener: opener),
          child: Text(l10n.privacyPolicyLink),
        ),
        TextButton(
          onPressed: () =>
              openLinkOrExplain(context, termsPageUri(), opener: opener),
          child: Text(l10n.termsLink),
        ),
      ],
    );
  }
}
