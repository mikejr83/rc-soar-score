import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../api_client_provider.dart';
import '../auth/auth_scope.dart';
import '../auth/auth_session.dart';
import '../l10n/app_localizations.dart';
import '../router.dart';
import '../session/contest_open_gate.dart';
import '../session/end_session.dart';
import '../session/guest_session_scope.dart';
import '../widgets/legal_footer.dart';

/// The landing page: brand lockup, what the app is for and the ways in.
///
/// Signed out it offers Sign in and Sign up (Auth0's Universal Login); with
/// no identity provider in the build the buttons stay off. Signed in it shows
/// who the pilot is, with the way to their contests and to sign out.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _failed = false;
  bool _busy = false;

  Future<void> _signIn(AuthSession auth, {required bool createAccount}) async {
    if (_busy) return;
    setState(() {
      _failed = false;
      _busy = true;
    });
    try {
      await auth.signIn(createAccount: createAccount);
    } on AuthException {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final auth = context.auth;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: BrandLogo(
                            variant: BrandLogoVariant.lockup,
                            height: 120,
                            semanticLabel:
                                'RC Soar Score, glider contest scoring',
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          l10n.homeHeadline,
                          style: theme.textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.homeIntro,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (auth.isSignedIn)
                          _SignedIn(auth: auth)
                        else
                          _SignedOut(
                            auth: auth,
                            failed: _failed,
                            busy: _busy,
                            onSignIn: () => _signIn(auth, createAccount: false),
                            onSignUp: () => _signIn(auth, createAccount: true),
                          ),
                        const Spacer(),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.mail_outline,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.homeLostLink,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const LegalFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut({
    required this.auth,
    required this.failed,
    required this.busy,
    required this.onSignIn,
    required this.onSignUp,
  });

  final AuthSession auth;
  final bool failed;

  /// A sign-in is in flight.
  final bool busy;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final available = auth.isAvailable;
    // Off while Auth0 starts or a sign-in is out: both start the same
    // callback handling, which must run once.
    final enabled = available && !auth.isInitializing && !busy;
    return Semantics(
      // Tells a screen reader why the buttons are off in a build with no
      // sign-in.
      hint: available ? null : l10n.homeAccountsUnavailableHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: enabled ? onSignIn : null,
            child: Text(l10n.signInButton),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: scheme.onSurface, width: 1.5),
            ),
            onPressed: enabled ? onSignUp : null,
            child: Text(l10n.homeSignUpButton),
          ),
          const SizedBox(height: 8),
          if (failed)
            Text(
              l10n.homeSignInFailed,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
            )
          else if (!available)
            Text(
              l10n.homeAccountsComingSoon,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _SignedIn extends StatefulWidget {
  const _SignedIn({required this.auth});

  final AuthSession auth;

  @override
  State<_SignedIn> createState() => _SignedInState();
}

class _SignedInState extends State<_SignedIn> {
  bool _failed = false;
  bool _pending = false;

  Future<void> _signOut() async {
    setState(() {
      _failed = false;
      _pending = true;
    });
    // Ends the contest session in this browser (the API's cookie and the
    // stored record, whether or not the record is there) before signing out,
    // so scoring access does not outlive the sign-in. No new opens from My
    // Contests, and every open already sent settles first: its answer may set
    // the cookie, and the clear has to come after that.
    final sessions = context.guestSessions;
    final client = context
        .getInheritedWidgetOfExactType<ApiClientInherited>()
        ?.client;
    final gate = context.contestOpenGate;
    try {
      await gate.closeAndSettle();
      final ended = await endGuestSession(
        client,
        sessions,
        clearOnFailure: false,
      );
      if (!ended) {
        gate.reopen();
        if (mounted) setState(() => _failed = true);
        return;
      }
      await widget.auth.signOut();
    } on Object {
      if (mounted) setState(() => _failed = true);
    } finally {
      // On the web a sign-out leaves the page; where it does not, the next
      // sign-in opens contests again.
      gate.reopen();
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final name = widget.auth.displayName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          name == null ? l10n.homeSignedIn : l10n.homeSignedInAs(name),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () => context.go(contestsPath),
          child: Text(l10n.homeMyContests),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            side: BorderSide(color: scheme.onSurface, width: 1.5),
          ),
          onPressed: _pending ? null : _signOut,
          child: Text(l10n.homeSignOutButton),
        ),
        if (_failed) ...[
          const SizedBox(height: 8),
          Text(
            l10n.homeSignOutFailed,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}
