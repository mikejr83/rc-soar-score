import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/landing_page.dart';
import '../router.dart';
import 'not_wired_up_dialog.dart';
import 'shell_destinations.dart';
import 'shell_stub_page.dart';

/// The shell's full-height navigation rail (Material 3).
///
/// The top holds a menu button that switches between the collapsed and the
/// expanded rail (wide windows only), the application title and, in the
/// system scope, a context-aware FAB: `Add participant` on the participant
/// pages, `Create contest` on the main page, and a stub for the other pages.
/// The destinations come from [shellDestinationsFor], so contest-only tasks
/// (matrix, scoring, reports) appear only while a contest is selected.
class ShellRail extends StatefulWidget {
  const ShellRail({super.key, required this.path});

  /// The current route path; selects the destination set and the active
  /// destination.
  final String path;

  /// The window width from which the rail can be expanded.
  static const double expandableWidth = 840;

  static const String notBuiltDetail = ShellStubPage.notBuiltDetail;

  @override
  State<ShellRail> createState() => _ShellRailState();
}

class _ShellRailState extends State<ShellRail> {
  bool _expanded = false;

  bool _isUnder(String location) =>
      widget.path == location || widget.path.startsWith('$location/');

  /// The label, key and action of the FAB for the current page.
  ({String label, Key key, VoidCallback onPressed}) _fab(BuildContext context) {
    if (_isUnder(participantsPath)) {
      return (
        label: 'Add participant',
        key: const ValueKey('add-participant'),
        onPressed: () => context.go(newParticipantPath),
      );
    }
    final (label, key) = switch (widget.path) {
      rolesPath => ('New role', const ValueKey('new-role')),
      landingsPath => ('New landing', const ValueKey('new-landing')),
      _ => ('Create contest', const ValueKey('create-contest')),
    };
    return (
      label: label,
      key: key,
      onPressed: () => showNotWiredUpDialog(
        context,
        label,
        detail: ShellRail.notBuiltDetail,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinations = shellDestinationsFor(widget.path);
    final selected = destinations.indexWhere(
      (destination) => destination.matches(widget.path),
    );
    final canExpand =
        MediaQuery.sizeOf(context).width >= ShellRail.expandableWidth;
    final expanded = canExpand && _expanded;
    final system = shellScopeFor(widget.path) == ShellScope.system;
    final fab = system ? _fab(context) : null;

    return NavigationRail(
      selectedIndex: selected < 0 ? null : selected,
      extended: expanded,
      labelType: expanded
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      leading: Column(
        crossAxisAlignment: expanded
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (canExpand)
            IconButton(
              key: const ValueKey('rail-toggle'),
              tooltip: expanded ? 'Collapse navigation' : 'Expand navigation',
              icon: Icon(expanded ? Icons.menu_open : Icons.menu),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          _RailTitle(expanded: expanded),
          if (fab != null) ...[
            const SizedBox(height: 12),
            if (expanded)
              FloatingActionButton.extended(
                key: fab.key,
                heroTag: null,
                elevation: 0,
                onPressed: fab.onPressed,
                icon: const Icon(Icons.add),
                label: Text(fab.label),
              )
            else
              FloatingActionButton(
                key: fab.key,
                heroTag: null,
                elevation: 0,
                tooltip: fab.label,
                onPressed: fab.onPressed,
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
            detail: ShellRail.notBuiltDetail,
          );
        }
      },
    );
  }
}

/// The application title at the top of the rail. Plain text, not a button,
/// so it cannot be mistaken for a destination or the rail's menu control.
class _RailTitle extends StatelessWidget {
  const _RailTitle({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final title = Text(
      LandingPage.title,
      key: const ValueKey('shell-title'),
      textAlign: expanded ? TextAlign.start : TextAlign.center,
      style:
          (expanded ? theme.textTheme.titleMedium : theme.textTheme.labelMedium)
              ?.copyWith(color: color),
    );
    return Semantics(
      header: true,
      child: expanded
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.paragliding, color: color),
                  const SizedBox(width: 8),
                  title,
                ],
              ),
            )
          : SizedBox(
              width: 72,
              child: Column(
                children: [
                  Icon(Icons.paragliding, color: color),
                  const SizedBox(height: 4),
                  title,
                ],
              ),
            ),
    );
  }
}
