import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../router.dart';

/// The app bar button that opens the Application info page, where the open
/// source licences, the Privacy Policy and the Terms are listed.
class AppInfoButton extends StatelessWidget {
  const AppInfoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context).appInfoLink,
      icon: const Icon(Icons.info_outline),
      onPressed: () => context.push(appInfoPath),
    );
  }
}
