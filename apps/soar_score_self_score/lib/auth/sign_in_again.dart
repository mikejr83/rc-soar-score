import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'auth_scope.dart';
import 'auth_session.dart';

/// Starts a new sign-in for a pilot whose sign-in the server no longer
/// accepts, and says so in a snack bar when it cannot be started. On the web
/// this leaves the page; Auth0 returns to the app's root.
Future<void> signInAgain(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    await context.auth.signIn();
  } on AuthException {
    messenger.showSnackBar(SnackBar(content: Text(l10n.homeSignInFailed)));
  }
}
