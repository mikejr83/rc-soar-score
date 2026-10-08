import 'package:flutter/material.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'landing_unit_text.dart';

/// The master pane of the Landings page: the title and count, then the
/// director's tables followed by the read-only system tables. The row for
/// [selectedId] is highlighted when [highlight] is set.
class LandingListPane extends StatelessWidget {
  const LandingListPane({
    super.key,
    required this.tables,
    required this.selectedId,
    required this.highlight,
    required this.onSelect,
  });

  /// Every visible table.
  final List<LandingTableView> tables;
  final Id? selectedId;
  final bool highlight;
  final ValueChanged<LandingTableView> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Landings', style: theme.textTheme.titleLarge),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '${tables.length} tables',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final view = tables[index];
              return ListTile(
                key: ValueKey('landing-${view.table.id.value}'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                selected: highlight && view.table.id == selectedId,
                selectedTileColor: theme.colorScheme.secondaryContainer,
                leading: Icon(
                  view.table.isSystem ? Icons.public : Icons.track_changes,
                ),
                title: Text(view.table.name),
                subtitle: Text(
                  '${view.table.isSystem ? 'System' : 'Yours'} · '
                  '${landingUnitLabel(view.table.inputUnit)} · '
                  '${view.results.length} entries',
                ),
                trailing: view.inUse
                    ? const Icon(Icons.lock_outline, size: 18)
                    : null,
                onTap: () => onSelect(view),
              );
            },
          ),
        ),
      ],
    );
  }
}
