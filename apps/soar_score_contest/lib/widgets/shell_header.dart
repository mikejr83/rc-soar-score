import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../contest_draft_provider.dart';
import '../l10n/app_localizations.dart';
import '../router.dart';
import 'new_contest/draft_status_label.dart';

/// The slim header at the top of the shell's content pane: a back arrow
/// below the main page (the participant pages have none; their root crumb
/// is the way back), a root
/// crumb (`Contests` or `Participants`) that returns to that page,
/// the selected contest's name in the contest scope, and plain-text crumbs
/// for deeper segments (go_router provides browser-history back on web).
///
/// In the New Contest wizard the crumbs read `Contests > New contest` and
/// the trailing end shows whether the draft is saved.
///
/// A centred page title names the selected page (with the contest's name
/// beneath it in the contest scope).
///
/// It spans the content pane only, leaving the rail full height and as much
/// vertical space as possible for the routed page.
class ShellHeader extends StatelessWidget {
  const ShellHeader({super.key, required this.path, this.contestName});

  final String path;

  /// The selected contest's name, once loaded; a generic word is shown until
  /// then.
  final String? contestName;

  static const double height = 64;

  /// Trailing segment standing for the `New` crumb.
  static const String _newSegment = 'new';

  /// Trailing segment standing for the `Edit` crumb.
  static const String _editSegment = 'edit';

  /// Trailing segment standing for the `New contest` crumb.
  static const String _newContestSegment = 'new-contest';

  /// The text of a trailing [segment]: a page the rail names, one of the
  /// editor crumbs, else the segment capitalized.
  static String _label(AppLocalizations l10n, String segment) =>
      switch (segment) {
        _newSegment => l10n.shellCrumbNew,
        _editSegment => l10n.shellCrumbEdit,
        _newContestSegment => l10n.shellCrumbNewContest,
        'workspace' => l10n.shellNavWorkspace,
        'configuration' => l10n.shellNavConfiguration,
        'participants' => l10n.shellNavParticipants,
        'matrix' => l10n.shellNavMatrix,
        'scoring' => l10n.shellNavScoring,
        'reports' => l10n.shellNavReports,
        'publication' => l10n.shellNavPublication,
        'sync' => l10n.shellNavSync,
        'settings' => l10n.shellNavSettings,
        _ =>
          segment.length > 1
              ? segment[0].toUpperCase() + segment.substring(1)
              : segment,
      };

  /// Whether [path] is the participant list or a page below it.
  static bool _isParticipants(String path) =>
      path == participantsPath || path.startsWith('$participantsPath/');

  /// The path, breadcrumb key suffix and label of the stub page (`Roles`,
  /// `Landings`, `Settings`) that [path] is, else `null`.
  static (String, String, String Function(AppLocalizations))? _stubRoot(
    String path,
  ) {
    if (path == landingsPath || path.startsWith('$landingsPath/')) {
      return (landingsPath, 'landings', (l10n) => l10n.shellNavLandings);
    }
    if (path == accountSyncPath) {
      return (
        accountSyncPath,
        'account-sync',
        (l10n) => l10n.shellNavAccountSync,
      );
    }
    if (path == settingsPath) {
      return (settingsPath, 'settings', (l10n) => l10n.shellNavSettings);
    }
    return path == rolesPath
        ? (rolesPath, 'roles', (l10n) => l10n.shellNavRoles)
        : null;
  }

  /// Path segments to show as plain crumbs after the root crumb (and the
  /// contest name in the contest scope). Participant ids are not shown;
  /// the editor reads `New` or `Edit`.
  static List<String> _trailingSegments(String path, String? contestId) {
    final String rest;
    if (_isParticipants(path)) {
      if (path == participantsPath) {
        return const [];
      }
      return [path == newParticipantPath ? _newSegment : _editSegment];
    } else if (_stubRoot(path) != null) {
      return path == newLandingPath ? const [_newSegment] : const [];
    } else if (path == newContestPath) {
      return const [_newContestSegment];
    } else if (contestId != null) {
      rest = path.substring('$contestsPath/$contestId'.length);
    } else if (path.startsWith('$homePath/')) {
      rest = path.substring(homePath.length);
    } else {
      return const [];
    }
    return rest.split('/').where((segment) => segment.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final contestFallback = l10n.shellContestFallback;
    final participants = _isParticipants(path);
    final stub = _stubRoot(path);
    final rootPath = participants ? participantsPath : stub?.$1 ?? homePath;
    final rootLabel = participants
        ? l10n.shellNavParticipants
        : stub?.$3(l10n) ?? l10n.shellNavContests;
    final rootKey = participants
        ? 'breadcrumb-participants'
        : stub != null
        ? 'breadcrumb-${stub.$2}'
        : 'breadcrumb-contests';
    final isRoot = path == rootPath;
    final contestId = contestIdFor(path);
    final draftStore = path == newContestPath
        ? contestDraftStoreOf(context)
        : null;
    final crumbStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final separator = Icon(
      Icons.chevron_right,
      size: 18,
      color: theme.colorScheme.onSurfaceVariant,
    );

    final trailing = _trailingSegments(path, contestId);
    // The title names the selected page: the deepest segment, else the
    // contest's page or the root page itself.
    final title = trailing.isNotEmpty
        ? _label(l10n, trailing.last)
        : contestId != null
        ? l10n.shellNavWorkspace
        : rootLabel;
    final crumbs = trailing.isEmpty
        ? const <String>[]
        : trailing.sublist(0, trailing.length - 1);

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 8, end: 16),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: TextButton(
                      key: ValueKey(rootKey),
                      onPressed: isRoot
                          ? null
                          : () => GoRouter.of(context).go(rootPath),
                      child: Text(rootLabel, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  if (contestId != null) ...[
                    separator,
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          contestName ?? contestFallback,
                          key: const ValueKey('contest-title'),
                          style: crumbStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  for (final segment in crumbs) ...[
                    separator,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(_label(l10n, segment), style: crumbStyle),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  key: const ValueKey('page-title'),
                  style: theme.textTheme.titleLarge,
                ),
                if (contestId != null)
                  Text(
                    contestName ?? contestFallback,
                    key: const ValueKey('page-subtitle'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: draftStore == null
                    ? null
                    : DraftStatusLabel(store: draftStore),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
