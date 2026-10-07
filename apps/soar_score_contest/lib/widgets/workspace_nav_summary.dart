import 'package:flutter/material.dart';

/// One destination in the workspace's navigation summary.
class WorkspaceDestination {
  const WorkspaceDestination({
    required this.label,
    required this.description,
    required this.icon,
  });

  final String label;
  final String description;
  final IconData icon;
}

/// The pages a contest's director moves between, in workspace order. Each
/// becomes openable as its page lands.
const List<WorkspaceDestination> workspaceDestinations = [
  WorkspaceDestination(
    label: 'Configuration',
    description: 'Contest rules, options and the matrix draw.',
    icon: Icons.tune,
  ),
  WorkspaceDestination(
    label: 'Participants',
    description: 'Who is flying in this contest.',
    icon: Icons.groups_outlined,
  ),
  WorkspaceDestination(
    label: 'Matrix',
    description: 'Rounds, groups and lane positions.',
    icon: Icons.grid_on_outlined,
  ),
  WorkspaceDestination(
    label: 'Scoring',
    description: 'Official score entry.',
    icon: Icons.scoreboard_outlined,
  ),
  WorkspaceDestination(
    label: 'Reports',
    description: 'Results and exports.',
    icon: Icons.assessment_outlined,
  ),
  WorkspaceDestination(
    label: 'Publication',
    description: 'What the public sees.',
    icon: Icons.public,
  ),
];

/// A card per [WorkspaceDestination]. A destination without a location in
/// [locations] is not available yet and is shown disabled.
class WorkspaceNavSummary extends StatelessWidget {
  const WorkspaceNavSummary({
    super.key,
    this.locations = const {},
    required this.onOpen,
  });

  /// Destination label to route location, for the pages that exist.
  final Map<String, String> locations;

  final void Function(String location) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final destination in workspaceDestinations)
          SizedBox(
            width: 260,
            child: Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                key: ValueKey('workspace-${destination.label.toLowerCase()}'),
                enabled: locations.containsKey(destination.label),
                leading: Icon(destination.icon),
                title: Text(destination.label),
                subtitle: Text(
                  locations.containsKey(destination.label)
                      ? destination.description
                      : '${destination.description} Not available yet.',
                  style: theme.textTheme.bodySmall,
                ),
                onTap: locations.containsKey(destination.label)
                    ? () => onOpen(locations[destination.label]!)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
