import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/sign_in_again.dart';
import '../data/self_score_repository.dart';
import '../data/self_score_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/account_link.dart';
import '../models/own_directory.dart';
import '../router.dart';
import '../widgets/loadable_scaffold.dart';
import '../widgets/past_contests_section.dart';
import '../widgets/self_score_app_bar.dart';
import '../widgets/signed_in_gate.dart';

/// What the account page shows: the pilot's directory entry and the pilots
/// their account is linked to.
class _AccountData {
  const _AccountData({required this.directory, required this.links});

  final OwnDirectory directory;
  final List<AccountLink> links;
}

/// The signed-in pilot's account (#654): what contest directors can find,
/// the pilots the account is linked to, and a way to unlink one. Details are
/// edited on the details page (#652), not here.
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  /// Bumped to load the page again after a change.
  int _reloads = 0;

  /// The link being ended, or `'entry'` while the directory entry goes.
  String? _busy;

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
    required Key actionKey,
  }) async {
    final l10n = AppLocalizations.of(context);
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            key: const Key('account-dialog-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.accountCancel),
          ),
          FilledButton(
            key: actionKey,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  Future<void> _run(
    String busy,
    Future<void> Function() change,
    String failure,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = busy);
    try {
      await change();
      if (mounted) setState(() => _reloads++);
    } on SignedOutException {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.accountSignInEnded),
          action: SnackBarAction(
            label: l10n.signInAgainButton,
            onPressed: () {
              if (mounted) signInAgain(context);
            },
          ),
        ),
      );
    } on SelfScoreLoadException {
      messenger.showSnackBar(SnackBar(content: Text(failure)));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _unlink(AccountLink link) async {
    final l10n = AppLocalizations.of(context);
    final repository = context.repository;
    if (_busy != null) return;
    final confirmed = await _confirm(
      title: l10n.accountUnlinkTitle,
      body: l10n.accountUnlinkBody,
      action: l10n.accountUnlinkConfirm,
      actionKey: const Key('account-unlink-confirm'),
    );
    if (!confirmed || !mounted) return;
    await _run(
      link.id,
      () => repository.endAccountLink(link.id),
      l10n.accountUnlinkFailed,
    );
  }

  Future<void> _removeEntry() async {
    final l10n = AppLocalizations.of(context);
    final repository = context.repository;
    if (_busy != null) return;
    final confirmed = await _confirm(
      title: l10n.accountRemoveTitle,
      body: l10n.accountRemoveBody,
      action: l10n.accountRemoveConfirm,
      actionKey: const Key('account-remove-confirm'),
    );
    if (!confirmed || !mounted) return;
    await _run(
      'entry',
      repository.deleteOwnDirectory,
      l10n.accountRemoveFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SignedInGate(title: l10n.accountTitle, builder: _buildSignedIn);
  }

  Widget _buildSignedIn(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = context.repository;
    return LoadableScaffold<_AccountData>(
      onSignedOut: () => signInAgain(context),
      load: () async {
        final results = await Future.wait<Object>([
          repository.ownDirectory(),
          repository.accountLinks(),
        ]);
        return _AccountData(
          directory: results[0] as OwnDirectory,
          links: results[1] as List<AccountLink>,
        );
      },
      reloadKey: (repository, _reloads),
      appBar: (context, data) => SelfScoreAppBar(
        title: l10n.accountTitle,
        showAccount: false,
        onBack: () => context.go(contestsPath),
        backLabel: l10n.accountBackToContests,
      ),
      builder: (context, data) => _AccountBody(
        data: data,
        busy: _busy,
        onUnlink: _unlink,
        onRemoveEntry: _removeEntry,
      ),
    );
  }
}

class _AccountBody extends StatelessWidget {
  const _AccountBody({
    required this.data,
    required this.busy,
    required this.onUnlink,
    required this.onRemoveEntry,
  });

  final _AccountData data;
  final String? busy;
  final void Function(AccountLink) onUnlink;
  final VoidCallback onRemoveEntry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final directory = data.directory;
    final details = directory.initial;
    final name = '${details.firstName} ${details.lastName}'.trim();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.accountDetailsHeading,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              key: const Key('account-details'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (directory.hasEntry) ...[
                      Text(name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        details.isListed
                            ? l10n.accountListed
                            : l10n.accountUnlisted,
                      ),
                      if (directory.emailAvailable)
                        Text(
                          details.emailVisibleToDirectors
                              ? l10n.accountEmailShared
                              : l10n.accountEmailPrivate,
                        ),
                    ] else
                      Text(l10n.accountNoEntry),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton.tonal(
                          key: const Key('account-edit-details'),
                          onPressed: busy != null
                              ? null
                              : () => context.go(detailsFromAccountPath),
                          child: Text(
                            directory.hasEntry
                                ? l10n.accountEditDetails
                                : l10n.accountSetDetails,
                          ),
                        ),
                        if (directory.hasEntry)
                          TextButton(
                            key: const Key('account-remove-entry'),
                            onPressed: busy != null ? null : onRemoveEntry,
                            child: Text(l10n.accountRemoveEntry),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(
                l10n.accountLinksHeading,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            if (data.links.isEmpty)
              Text(
                l10n.accountLinksEmpty,
                key: const Key('account-links-empty'),
              )
            else
              for (final link in data.links)
                Card(
                  key: Key('account-link-${link.id}'),
                  child: ListTile(
                    title: Text(link.pilotName),
                    // The label names the pilot: the buttons all read "Unlink".
                    trailing: Semantics(
                      label: l10n.accountUnlinkFor(link.pilotName),
                      button: true,
                      excludeSemantics: true,
                      onTap: busy != null ? null : () => onUnlink(link),
                      child: TextButton(
                        key: Key('account-unlink-${link.id}'),
                        onPressed: busy != null ? null : () => onUnlink(link),
                        child: Text(l10n.accountUnlink),
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 24),
            // Keyed by the links, so unlinking (which removes that pilot's
            // contests) loads the history again.
            PastContestsSection(
              key: Key('account-past-${[for (final l in data.links) l.id]}'),
            ),
          ],
        ),
      ),
    );
  }
}
