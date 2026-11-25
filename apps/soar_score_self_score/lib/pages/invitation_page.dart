import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../auth/auth_scope.dart';
import '../auth/auth_session.dart';
import '../data/self_score_repository.dart';
import '../data/self_score_scope.dart';
import '../l10n/app_localizations.dart';
import '../public_site.dart';
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

  /// Claims the link for the signed-in account. The guest entries stay with
  /// the pilot under the account, and the session answered acts as it.
  Future<ClaimFailure?> _claim() async {
    try {
      final session = await context.repository.claimInvitation(
        widget.credential,
      );
      if (!mounted) return null;
      _continueAsGuest(session);
      return null;
    } on PilotAlreadyLinkedException {
      return ClaimFailure.alreadyLinked;
    } on AccountSignInExpiredException {
      return ClaimFailure.signInExpired;
    } on AccountCannotLinkException {
      return ClaimFailure.cannotLink;
    } on InvalidInvitationException {
      return ClaimFailure.invalid;
    } on Object {
      return ClaimFailure.unreachable;
    }
  }

  Future<void> _signIn(AuthSession auth, {required bool createAccount}) async {
    // The redirect leaves the page: ask to come back to this link.
    await auth.signIn(
      createAccount: createAccount,
      returnTo: invitationPath(widget.credential),
    );
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
                    onClaim: _claim,
                    onSignIn: (auth, {required createAccount}) =>
                        _signIn(auth, createAccount: createAccount),
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
                    supportUri: supportPageUri(),
                    supportLabel: l10n.supportLink,
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

/// Why claiming a link for the signed-in account did not work.
enum ClaimFailure {
  alreadyLinked,
  signInExpired,
  cannotLink,
  invalid,
  unreachable,
}

class _Welcome extends StatefulWidget {
  const _Welcome({
    required this.session,
    required this.onContinue,
    required this.onClaim,
    required this.onSignIn,
  });

  final GuestSession session;
  final VoidCallback onContinue;
  final Future<ClaimFailure?> Function() onClaim;
  final Future<void> Function(AuthSession auth, {required bool createAccount})
  onSignIn;

  @override
  State<_Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<_Welcome> {
  bool _claiming = false;
  ClaimFailure? _failure;
  bool _signInFailed = false;
  bool _signingIn = false;

  Future<void> _claim() async {
    setState(() {
      _claiming = true;
      _failure = null;
      _signInFailed = false;
    });
    final failure = await widget.onClaim();
    if (mounted) {
      setState(() {
        _claiming = false;
        _failure = failure;
      });
    }
  }

  Future<void> _signIn(AuthSession auth, {required bool createAccount}) async {
    if (_signingIn) return;
    setState(() {
      _signInFailed = false;
      _signingIn = true;
    });
    try {
      await widget.onSignIn(auth, createAccount: createAccount);
    } on AuthException {
      if (mounted) setState(() => _signInFailed = true);
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auth = context.auth;
    final session = widget.session;
    final signedIn = auth.isSignedIn;
    final name = auth.displayName;
    final failure = _failure;
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
          signedIn
              ? l10n.invitationClaimBody(session.contestName)
              : l10n.invitationBody(session.contestName),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        if (signedIn) ...[
          // Signed in: the primary choice keeps the pilot's scores, including
          // any entered as a guest, with the account.
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: _claiming ? null : _claim,
            child: Text(
              name == null ? l10n.continueAsAccount : l10n.continueAsName(name),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _claiming ? null : widget.onContinue,
            child: Text(l10n.continueAsGuest),
          ),
          if (failure != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                switch (failure) {
                  ClaimFailure.alreadyLinked => l10n.claimAlreadyLinked,
                  ClaimFailure.signInExpired => l10n.claimSignInExpired,
                  ClaimFailure.cannotLink => l10n.claimCannotLink,
                  ClaimFailure.invalid => l10n.claimInvalid,
                  ClaimFailure.unreachable => l10n.claimFailed,
                },
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                ),
              ),
            ),
          ],
        ] else ...[
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: widget.onContinue,
            child: Text(l10n.continueAsGuest),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: auth.isAvailable && !auth.isInitializing && !_signingIn
                ? () => _signIn(auth, createAccount: false)
                : null,
            child: Text(l10n.signInButton),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: auth.isAvailable && !auth.isInitializing && !_signingIn
                ? () => _signIn(auth, createAccount: true)
                : null,
            child: Text(l10n.createAccountButton),
          ),
          const SizedBox(height: 12),
          Text(
            _signInFailed
                ? l10n.homeSignInFailed
                : auth.isAvailable
                ? l10n.invitationKeepScores
                : l10n.accountsComingSoon,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _signInFailed ? scheme.error : scheme.onSurfaceVariant,
            ),
          ),
        ],
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
