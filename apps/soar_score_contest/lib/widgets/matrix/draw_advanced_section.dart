import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/matrix/draw_form_controller.dart';

/// Random seed, attempts per round and seed count, collapsed by default.
class DrawAdvancedSection extends StatelessWidget {
  const DrawAdvancedSection({super.key, required this.controller});

  final DrawFormController controller;

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
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const ValueKey('advanced'),
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
                  controller.seed,
                  'Pick one for me',
                  'Same seed and settings give the same matrix. Leave blank '
                      'and the server picks one.',
                ),
                field(
                  const ValueKey('draw-attempts'),
                  'Attempts per round',
                  controller.attempts,
                  '${DrawFormController.defaultAttempts}',
                  'Groupings the server tries for each round. More attempts '
                      'can improve fairness.',
                ),
                field(
                  const ValueKey('draw-seed-count'),
                  'Seed count',
                  controller.seedCount,
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
