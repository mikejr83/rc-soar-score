import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../data/self_score_repository.dart';
import '../data/self_score_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/guest_session.dart';
import '../router.dart';
import '../session/guest_session_scope.dart';
import '../widgets/legal_footer.dart';
import '../widgets/load_error_view.dart';

/// Where an invitation link lands. Checks the credential, then lets the pilot
/// continue as a guest. Accepting stores the guest session and replaces the
/// address with the pilot overview, so the credential is not left in the
/// browser history.
class InvitationPage extends StatefulWidget {
  const InvitationPage({required this.credential, super.key});

  final String credential;

  @override
  State<InvitationPage> createState() => _InvitationPageState();
}

class _InvitationPageState extends State<InvitationPage> {
  Future<GuestSession>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.repository.acceptInvitation(widget.credential);
  }

  void _retry() {
    setState(() {
      _future = context.repository.acceptInvitation(widget.credential);
    });
  }

  void _continueAsGuest(GuestSession session) {
    context.guestSessions.write(session);
    context.pushReplacement(pilotPath(session.contestId, session.pilotId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: FutureBuilder<GuestSession>(
              future: _future,
              builder: (context, snapshot) {
                final session = snapshot.data;
                if (session != null && session.role != 'pilot') {
                  // A link for another role: this release has no page for it,
                  // and it is not treated as a pilot.
                  return const _UnsupportedRole();
                }
                if (session != null) {
                  return _Welcome(
                    session: session,
                    onContinue: () => _continueAsGuest(session),
                  );
                }
                final error = snapshot.error;
                if (error is InvalidInvitationException) {
                  return const _InvalidLink();
                }
                if (error != null) {
                  return LoadErrorView(
                    message: l10n.invitationLoadFailed,
                    onRetry: _retry,
                  );
                }
                return Center(
                  child: Semantics(
                    label: l10n.invitationOpening,
                    child: const CircularProgressIndicator(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.session, required this.onContinue});

  final GuestSession session;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      children: [
        const Center(
          child: BrandLogo(
            variant: BrandLogoVariant.lockup,
            height: 96,
            semanticLabel: 'RC Soar Score, glider contest scoring',
          ),
        ),
        const SizedBox(height: 32),
        Text(
          l10n.invitationHeading(session.pilotName),
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.invitationBody(session.contestName),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: onContinue,
          child: Text(l10n.continueAsGuest),
        ),
        const SizedBox(height: 12),
        // Not connected until sign-in exists (#545, #546).
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: null,
          child: Text(l10n.signInButton),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: null,
          child: Text(l10n.createAccountButton),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.accountsComingSoon,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        const LegalFooter(),
      ],
    );
  }
}

/// A valid link for a role this release does not support yet.
class _UnsupportedRole extends StatelessWidget {
  const _UnsupportedRole();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.unsupportedRoleTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.unsupportedRoleBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          const LegalFooter(),
        ],
      ),
    );
  }
}

/// One message for an unknown, expired and replaced link.
class _InvalidLink extends StatelessWidget {
  const _InvalidLink();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.link_off,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.invalidLinkTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.invalidLinkBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          const LegalFooter(),
        ],
      ),
    );
  }
}
