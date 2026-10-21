import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../collapsible_areas_provider.dart';
import '../../services/collapsible_areas/collapsible_area.dart';
import '../../services/matrix/draw_form_controller.dart';

/// Random seed, attempts per round and seed count, collapsed by default.
/// The choice is remembered per account ([drawAdvancedArea]).
class DrawAdvancedSection extends StatefulWidget {
  const DrawAdvancedSection({super.key, required this.controller});

  final DrawFormController controller;

  static const saveFailedMessage =
      'The section choice could not be saved. It applies until you close '
      'the app.';

  @override
  State<DrawAdvancedSection> createState() => _DrawAdvancedSectionState();
}

class _DrawAdvancedSectionState extends State<DrawAdvancedSection> {
  /// The user's choice when nothing remembers it (tests without the app).
  bool? _local;

  bool get _open {
    final areas = collapsibleAreasOf(context);
    if (areas == null) {
      return _local ?? false;
    }
    return areas.isOpen(drawAdvancedArea, fallback: false);
  }

  Future<void> _openChanged(bool open) async {
    final areas = collapsibleAreasOf(context);
    if (areas == null) {
      setState(() => _local = open);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (await areas.setOpen(drawAdvancedArea, open)) return;
    messenger.showSnackBar(
      const SnackBar(content: Text(DrawAdvancedSection.saveFailedMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget field(
      Key key,
      String label,
      TextEditingController text,
      String hint,
      String help,
    ) => ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: key,
            controller: text,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              help,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
    final open = _open;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        // The key tracks the choice so the tile re-syncs when a stored
        // choice arrives after the first frame (the app loads the choices
        // without awaiting). The form's text controllers are owned by the
        // page, so recreating the tile keeps the typed values.
        child: ExpansionTile(
          key: ValueKey('draw-advanced-$open'),
          initiallyExpanded: open,
          onExpansionChanged: _openChanged,
          title: const Text('Advanced'),
          subtitle: const Text('Random seed, attempts per round, seed count'),
          shape: const Border(),
          collapsedShape: const Border(),
          childrenPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 20,
              children: [
                field(
                  const ValueKey('draw-seed'),
                  'Random seed',
                  widget.controller.seed,
                  'Pick one for me',
                  'Same seed and settings give the same matrix. Leave blank '
                      'and the server picks one.',
                ),
                field(
                  const ValueKey('draw-attempts'),
                  'Attempts per round',
                  widget.controller.attempts,
                  '${DrawFormController.defaultAttempts}',
                  'Groupings the server tries for each round. More attempts '
                      'can improve fairness.',
                ),
                field(
                  const ValueKey('draw-seed-count'),
                  'Seed count',
                  widget.controller.seedCount,
                  '${DrawFormController.defaultSeedCount}',
                  'Independent starts the server runs. The fairest result is '
                      'kept.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
