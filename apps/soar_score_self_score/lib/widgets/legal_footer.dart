import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../router.dart';

/// Footer link for pages without an app bar, such as the landing page where
/// pilots sign in or sign up: it opens the Application info page.
class LegalFooter extends StatelessWidget {
  const LegalFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => context.push(appInfoPath),
        child: Text(AppLocalizations.of(context).appInfoLink),
      ),
    );
  }
}
