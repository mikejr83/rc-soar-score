import 'package:flutter/material.dart';

import '../../services/new_contest/copy_source.dart';

/// Picks which of the source contest's pilots to copy (for example for a
/// fly-off). Returns the chosen profile ids, or `null` when cancelled.
Future<Set<String>?> showChoosePilotsDialog(
  BuildContext context, {
  required List<SourcePilot> pilots,
  required Set<String> selected,
}) => showDialog<Set<String>>(
  context: context,
  builder: (context) => _ChoosePilotsDialog(pilots: pilots, selected: selected),
);

class _ChoosePilotsDialog extends StatefulWidget {
  const _ChoosePilotsDialog({required this.pilots, required this.selected});

  final List<SourcePilot> pilots;
  final Set<String> selected;

  @override
  State<_ChoosePilotsDialog> createState() => _ChoosePilotsDialogState();
}

class _ChoosePilotsDialogState extends State<_ChoosePilotsDialog> {
  late final Set<String> _selected = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    final all = _selected.length == widget.pilots.length;
    return AlertDialog(
      icon: const Icon(Icons.groups),
      title: const Text('Choose pilots to copy'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Each pilot is copied with their class. '
              '${_selected.length} of ${widget.pilots.length} selected.',
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: all,
              title: const Text('All pilots'),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) => setState(() {
                _selected.clear();
                if (value ?? false) {
                  _selected.addAll(
                    widget.pilots.map((pilot) => pilot.profileId.value),
                  );
                }
              }),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final pilot in widget.pilots)
                    CheckboxListTile(
                      value: _selected.contains(pilot.profileId.value),
                      title: Text(pilot.name),
                      subtitle: pilot.classification == null
                          ? null
                          : Text(pilot.classification!),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) => setState(() {
                        if (value ?? false) {
                          _selected.add(pilot.profileId.value);
                        } else {
                          _selected.remove(pilot.profileId.value);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Use these pilots'),
        ),
      ],
    );
  }
}
