import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_mode_provider.dart';
import '../auth/auth_session.dart';
import '../auth/auth_session_inherited.dart';
import '../router.dart';
import 'not_wired_up_dialog.dart';

/// The account control at the bottom of the shell rail.
///
/// Signed in, it is the user's picture; its menu names the user and offers
/// `Settings` and `Sign out`. Signed out it is a gear: in the offline desktop
/// app its menu offers `Sign in` and `Settings` (there is no account to show),
/// otherwise it opens the not-yet-available settings dialog.
class ShellAccountButton extends StatelessWidget {
  const ShellAccountButton({super.key});

  static const settingsLabel = 'Settings';
  static const settingsDetail = 'Settings are not built yet.';

  static void _openSettings(BuildContext context) =>
      showNotWiredUpDialog(context, settingsLabel, detail: settingsDetail);

  /// Ends the session, then returns to the landing page. The navigation
  /// guard redirects on its own when the session ends; going there here too
  /// keeps the result the same when it has not run yet.
  static Future<void> _signOut(
    BuildContext context,
    AuthSession session,
  ) async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await session.signOut();
    } on AuthException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    router.go(landingPath);
  }

  static void _signIn(BuildContext context) {
    appModeOf(context)?.exitOfflineMode();
    GoRouter.of(context).go(landingPath);
  }

  @override
  Widget build(BuildContext context) {
    final session = authSessionOf(context);
    if (session != null && session.isSignedIn) {
      return _signedIn(context, session);
    }
    if (isOfflineModeOf(context)) {
      return PopupMenuButton<VoidCallback>(
        key: const ValueKey('account-menu'),
        tooltip: 'Settings and sign in',
        icon: const Icon(Icons.settings_outlined),
        onSelected: (action) => action(),
        itemBuilder: (_) => [
          PopupMenuItem(
            value: () => _signIn(context),
            child: const ListTile(
              leading: Icon(Icons.login),
              title: Text('Sign in'),
            ),
          ),
          PopupMenuItem(
            value: () => _openSettings(context),
            child: const ListTile(
              leading: Icon(Icons.settings_outlined),
              title: Text(settingsLabel),
            ),
          ),
        ],
      );
    }
    return IconButton(
      key: const ValueKey('settings-button'),
      tooltip: settingsLabel,
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => _openSettings(context),
    );
  }

  Widget _signedIn(BuildContext context, AuthSession session) {
    final name = session.displayName ?? 'Signed in';
    return PopupMenuButton<VoidCallback>(
      key: const ValueKey('account-menu'),
      tooltip: 'Account: $name',
      onSelected: (action) => action(),
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            name,
            key: const ValueKey('account-name'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: () => _openSettings(context),
          child: const ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text(settingsLabel),
          ),
        ),
        PopupMenuItem(
          value: () => _signOut(context, session),
          child: const ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sign out'),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: _Avatar(name: name, pictureUrl: session.pictureUrl),
      ),
    );
  }
}

/// The user's picture, or their initial while it is missing or fails to load.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.pictureUrl});

  final String name;
  final Uri? pictureUrl;

  static const double size = 36;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = Text(
      name.isEmpty ? '?' : name.characters.first.toUpperCase(),
      style: TextStyle(color: scheme.onPrimaryContainer),
    );
    final url = pictureUrl;
    return Semantics(
      label: 'Account menu',
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: scheme.primaryContainer,
        child: url == null
            ? initial
            : ClipOval(
                child: Image.network(
                  url.toString(),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => initial,
                ),
              ),
      ),
    );
  }
}
