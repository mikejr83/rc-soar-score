import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../api_client_provider.dart';
import '../auth/auth_scope.dart';
import '../auth/auth_session.dart';
import '../data/self_score_repository.dart';
import '../data/self_score_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/contests_view.dart';
import '../public_site.dart';
import '../router.dart';
import '../session/contest_open_gate.dart';
import '../session/end_session.dart';
import '../session/guest_session_scope.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/contest_card.dart';
import '../widgets/is_this_you_card.dart';
import '../widgets/loadable_scaffold.dart';
import '../widgets/self_score_app_bar.dart';

/// The signed-in person's contests: in progress, invited and completed, each
/// opening the contest as their account. Signed out it asks the person to
/// sign in.
class ContestsPage extends StatefulWidget {
  const ContestsPage({this.opener = openInBrowser, super.key});

  /// Opens a public results address.
  final UrlOpener opener;

  @override
  State<ContestsPage> createState() => _ContestsPageState();
}

class _ContestsPageState extends State<ContestsPage> {
  /// The participation being opened; the list ignores taps meanwhile.
  String? _opening;

  /// Bumped to load the list again, such as after a contest left it.
  int _reloads = 0;

  Future<void> _open(ContestSummary contest) async {
    final repository = context.repository;
    final sessions = context.guestSessions;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final l10n = AppLocalizations.of(context);
    final auth = context.auth;
    final gate = context.contestOpenGate;
    final client = context
        .getInheritedWidgetOfExactType<ApiClientInherited>()
        ?.client;
    setState(() => _opening = contest.participationId);
    try {
      final session = await gate.run(
        () => repository.openContest(contest.participationId),
      );
      // Null: a sign-out is under way and refused the open.
      if (session == null) return;
      if (!auth.isSignedIn) {
        // Signed out while the contest was opening: the answer set a fresh
        // cookie, so end it instead of keeping it.
        await endGuestSession(client, sessions);
        return;
      }
      sessions.write(session);
      router.go(pilotPath(session.contestId, session.pilotId));
    } on ContestNotOnListException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.contestNotOnList)));
      if (mounted) setState(() => _reloads++);
    } on SignedOutException {
      // The server refused a token the provider still holds: offer signing in
      // again right here. The guest session, if any, is left alone.
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.contestSignInEnded),
          action: SnackBarAction(
            label: l10n.signInButton,
            onPressed: () => _reauthenticate(auth),
          ),
        ),
      );
    } on SelfScoreLoadException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.contestOpenFailed)));
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  Future<void> _reauthenticate(AuthSession auth) async {
    try {
      await auth.signIn();
    } on AuthException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).homeSignInFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!context.auth.isSignedIn) {
      return Scaffold(
        appBar: SelfScoreAppBar(title: l10n.contestsTitle),
        body: SafeArea(child: _SignedOut(auth: context.auth)),
      );
    }
    final repository = context.repository;
    return LoadableScaffold<ContestsView>(
      load: repository.contests,
      reloadKey: (repository, _reloads),
      onSignedOut: () => _reauthenticate(context.auth),
      appBar: (context, data) => SelfScoreAppBar(
        title: l10n.contestsTitle,
        actions: const [ConnectionIndicator()],
      ),
      builder: (context, data) => _List(
        view: data,
        opening: _opening,
        onOpen: _open,
        onOpenResults: (uri) =>
            openLinkOrExplain(context, uri, opener: widget.opener),
      ),
    );
  }
}

class _SignedOut extends StatefulWidget {
  const _SignedOut({required this.auth});

  final AuthSession auth;

  @override
  State<_SignedOut> createState() => _SignedOutState();
}

class _SignedOutState extends State<_SignedOut> {
  bool _failed = false;

  Future<void> _signIn() async {
    setState(() => _failed = false);
    try {
      await widget.auth.signIn();
    } on AuthException {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final available = widget.auth.isAvailable;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.contestsSignedOutMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Semantics(
              hint: available ? null : l10n.homeAccountsUnavailableHint,
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: available ? _signIn : null,
                child: Text(l10n.signInButton),
              ),
            ),
            const SizedBox(height: 8),
            if (_failed)
              Text(
                l10n.homeSignInFailed,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                ),
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
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.view,
    required this.opening,
    required this.onOpen,
    required this.onOpenResults,
  });

  final ContestsView view;
  final String? opening;
  final void Function(ContestSummary contest) onOpen;
  final void Function(Uri address) onOpenResults;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final locale = Localizations.localeOf(context).toString();
    final format = DateFormat.yMMMEd(locale);
    String dates(ContestSummary contest) => contest.startDate == contest.endDate
        ? format.format(contest.startDate)
        : l10n.contestDatesRange(
            format.format(contest.startDate),
            format.format(contest.endDate),
          );

    Widget section(String heading, ContestPhase phase, {String? note}) {
      final contests = view.inPhase(phase);
      if (contests.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(heading, style: theme.textTheme.titleLarge),
          ),
          if (note != null)
            Text(
              note,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          const SizedBox(height: 8),
          for (final contest in contests) ...[
            ContestCard(
              name: contest.name,
              dates: dates(contest),
              location: contest.location,
              phase: contest.phase,
              busy: opening == contest.participationId,
              onTap: opening == null ? () => onOpen(contest) : null,
              onOpenResults: contest.publicResultsUrl == null
                  ? null
                  : () => onOpenResults(contest.publicResultsUrl!),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (view.matchPrompt != null) ...[
          IsThisYouCard(message: view.matchPrompt!),
          const SizedBox(height: 16),
        ],
        if (view.contests.isEmpty) ...[
          const SizedBox(height: 24),
          Icon(Icons.flight_outlined, size: 40, color: muted),
          const SizedBox(height: 12),
          Text(
            l10n.contestsEmptyTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.contestsEmptyBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: muted),
          ),
        ] else ...[
          section(l10n.contestPhaseInProgress, ContestPhase.inProgress),
          section(l10n.contestPhaseInvited, ContestPhase.invited),
          section(
            l10n.contestPhaseCompleted,
            ContestPhase.completed,
            note: l10n.contestsCompletedNote,
          ),
        ],
      ],
    );
  }
}
