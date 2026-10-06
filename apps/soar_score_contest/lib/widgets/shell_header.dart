import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import 'shell_destinations.dart';

/// The slim header at the top of the shell's content pane: a back arrow
/// below the main page, a `Contests` crumb that returns to the main page,
/// the selected contest's name in the contest scope, and plain-text crumbs
/// for deeper segments (go_router provides browser-history back on web).
///
/// It spans the content pane only, leaving the rail full height and as much
/// vertical space as possible for the routed page.
class ShellHeader extends StatelessWidget {
  const ShellHeader({super.key, required this.path, this.contestName});

  final String path;

  /// The selected contest's name, once loaded; [contestFallback] is shown
  /// until then.
  final String? contestName;

  static const String contestFallback = 'Contest';

  static const double height = 48;

  static String _label(String segment) => segment.length > 1
      ? segment[0].toUpperCase() + segment.substring(1)
      : segment;

  /// Path segments to show as plain crumbs after the `Contests` crumb (and
  /// the contest name in the contest scope).
  static List<String> _trailingSegments(String path, String? contestId) {
    final String rest;
    if (contestId != null) {
      rest = path.substring('$contestsPath/$contestId'.length);
    } else if (path.startsWith('$homePath/')) {
      rest = path.substring(homePath.length);
    } else {
      return const [];
    }
    return rest.split('/').where((segment) => segment.isNotEmpty).toList();
  }

  void _back(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(homePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHome = path == homePath;
    final contestId = contestIdFor(path);
    final crumbStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final separator = Icon(
      Icons.chevron_right,
      size: 18,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 8, end: 16),
        child: Row(
          children: [
            if (!isHome)
              IconButton(
                key: const ValueKey('breadcrumb-back'),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => _back(context),
              ),
            TextButton(
              key: const ValueKey('breadcrumb-contests'),
              onPressed: isHome
                  ? null
                  : () => GoRouter.of(context).go(homePath),
              child: const Text('Contests'),
            ),
            if (contestId != null) ...[
              separator,
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    contestName ?? contestFallback,
                    key: const ValueKey('contest-title'),
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            for (final segment in _trailingSegments(path, contestId)) ...[
              separator,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(_label(segment), style: crumbStyle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
