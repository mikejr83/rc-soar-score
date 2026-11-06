import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api_client_provider.dart';
import '../l10n/app_localizations.dart';
import '../router.dart';
import '../session/end_session.dart';
import '../session/guest_session_scope.dart';

/// Ends the guest session and goes back to the start page. Shown only while
/// there is a session to end.
class EndSessionButton extends StatelessWidget {
  const EndSessionButton({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = context.guestSessions;
    if (sessions.read() == null) return const SizedBox.shrink();
    return IconButton(
      tooltip: AppLocalizations.of(context).endSession,
      icon: const Icon(Icons.logout),
      onPressed: () async {
        final client = context
            .getInheritedWidgetOfExactType<ApiClientInherited>()
            ?.client;
        await endGuestSession(client, sessions);
        if (context.mounted) context.go(homePath);
      },
    );
  }
}
