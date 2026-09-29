import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../connectivity_provider.dart';
import '../pages/landing_page.dart';
import '../router.dart';
import 'connectivity_indicator.dart';
import 'contest_status_bar.dart';
import 'not_wired_up_dialog.dart';

/// The persistent contest-administration shell (ticket 020): title area with
/// connectivity chips, breadcrumb/back navigation, a navigation rail for
/// administration tasks, the route's [child] content, and a status bar.
class ContestShell extends StatelessWidget {
  const ContestShell({super.key, required this.state, required this.child});

  /// The matched route state; drives the rail's selected destination and the
  /// breadcrumb/back arrow.
  final GoRouterState state;

  final Widget child;

  /// The navigation-rail destinations. Only "Landing" is wired; the rest show
  /// the not-wired-up dialog until their routes land (tickets 022 ff.).
  static const List<_RailDestination> _destinations = [
    _RailDestination(
      label: 'Landing',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      location: landingPath,
    ),
    _RailDestination(
      label: 'Contests',
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
    ),
    _RailDestination(
      label: 'Matrix',
      icon: Icons.grid_on_outlined,
      selectedIcon: Icons.grid_on,
    ),
    _RailDestination(
      label: 'Scoring',
      icon: Icons.edit_note_outlined,
      selectedIcon: Icons.edit_note,
    ),
    _RailDestination(
      label: 'Reports',
      icon: Icons.assessment_outlined,
      selectedIcon: Icons.assessment,
    ),
  ];

  /// The rail destination a location belongs to: a destination with a wired
  /// route is selected for its exact path and anything under it. Unwired
  /// destinations (no route yet) are never selected.
  int _selectedIndex(String location) => _destinations.indexWhere(
    (destination) =>
        destination.location != null &&
        (location == destination.location ||
            location.startsWith('${destination.location}/')),
  );

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

    // The indicators exist only when a bootstrap created the monitor (D5):
    // tests that pump the app without one see no chips.
    final monitor = appConnectivityOf(context);
    if (monitor != null) {
      // Internet first; hidden when the host cannot report connectivity at
      // all (decision D8).
      if (monitor.supportsConnectivity) {
        actions.add(ConnectivityIndicator.internet(monitor));
      }
      actions.add(ConnectivityIndicator.api(monitor));
    }

    final path = state.uri.path;
    final isLanding = path == landingPath;

    return Scaffold(
      appBar: AppBar(
        title: const Text(LandingPage.title),
        automaticallyImplyLeading: false,
        actions: actions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: _Breadcrumb(
            isLanding: isLanding,
            pathSegments: path
                .split('/')
                .where((segment) => segment.isNotEmpty)
                .toList(),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex(path),
                  extended: false,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final destination in _destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(destination.label),
                      ),
                  ],
                  onDestinationSelected: (index) {
                    final destination = _destinations[index];
                    if (destination.location != null) {
                      GoRouter.of(context).go(destination.location!);
                    } else {
                      showNotWiredUpDialog(context, destination.label);
                    }
                  },
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: child),
              ],
            ),
          ),
          const ContestStatusBar(),
        ],
      ),
    );
  }
}

/// One navigation-rail destination. [location] is `null` for destinations
/// whose route does not exist yet.
class _RailDestination {
  const _RailDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.location,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String? location;
}

/// The AppBar breadcrumb row: a "Landing" crumb that navigates to the root,
/// plain-text crumbs for deeper segments, and a back arrow for any path
/// below the landing page (go_router provides browser-history back on web).
class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.isLanding, required this.pathSegments});

  final bool isLanding;
  final List<String> pathSegments;

  static String _label(String segment) => segment.length > 1
      ? segment[0].toUpperCase() + segment.substring(1)
      : segment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final crumbs = <Widget>[
      TextButton(
        onPressed: isLanding
            ? null
            : () => GoRouter.of(context).go(landingPath),
        child: const Text('Landing'),
      ),
      for (final segment in isLanding ? const <String>[] : pathSegments)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            _label(segment),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
    ];

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16),
      child: Row(
        children: [
          if (!isLanding)
            IconButton(
              key: const ValueKey('breadcrumb-back'),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: () {
                final router = GoRouter.of(context);
                if (router.canPop()) {
                  router.pop();
                }
              },
            ),
          Expanded(
            child: Row(mainAxisSize: MainAxisSize.min, children: crumbs),
          ),
        ],
      ),
    );
  }
}
