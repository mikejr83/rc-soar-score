import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/landing_page.dart';
import 'not_wired_up_dialog.dart';
import 'shell_destinations.dart';

/// The shell's full-height navigation rail (Material 3 collapsed rail).
///
/// The top holds the application title and, in the system scope, the
/// `Create contest` FAB (the main page's key action). The destinations come
/// from [shellDestinationsFor], so contest-only tasks (matrix, scoring,
/// reports) appear only while a contest is selected.
class ShellRail extends StatelessWidget {
  const ShellRail({super.key, required this.path});

  /// The current route path; selects the destination set and the active
  /// destination.
  final String path;

  static const String notBuiltDetail =
      'This page has not been built yet. Please check back soon.';

  @override
  Widget build(BuildContext context) {
    final destinations = shellDestinationsFor(path);
    final selected = destinations.indexWhere(
      (destination) => destination.matches(path),
    );

    return NavigationRail(
      selectedIndex: selected < 0 ? null : selected,
      labelType: NavigationRailLabelType.all,
      leading: Column(
        children: [
          const _RailTitle(),
          if (shellScopeFor(path) == ShellScope.system) ...[
            const SizedBox(height: 12),
            FloatingActionButton(
              key: const ValueKey('create-contest'),
              heroTag: null,
              elevation: 0,
              tooltip: 'Create contest',
              onPressed: () => showNotWiredUpDialog(
                context,
                'Create contest',
                detail: notBuiltDetail,
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ],
      ),
      destinations: [
        for (final destination in destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: Text(destination.label),
          ),
      ],
      onDestinationSelected: (index) {
        final destination = destinations[index];
        final location = destination.location;
        if (location != null) {
          GoRouter.of(context).go(location);
        } else {
          showNotWiredUpDialog(
            context,
            destination.label,
            detail: notBuiltDetail,
          );
        }
      },
    );
  }
}

/// The application title at the top of the rail. Plain text, not a button,
/// so it cannot be mistaken for a destination or the rail's menu control.
class _RailTitle extends StatelessWidget {
  const _RailTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Icon(Icons.paragliding, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              LandingPage.title,
              key: const ValueKey('shell-title'),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
