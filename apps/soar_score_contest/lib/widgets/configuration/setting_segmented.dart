import 'package:flutter/material.dart';

import '../../services/configuration/setting_def.dart';

/// A segmented button over the options of a setting, with a check mark on
/// the selected one.
class SettingSegmented extends StatelessWidget {
  const SettingSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.focusNode,
  });

  final List<SettingOption> options;
  final Object? selected;

  /// `null` disables the buttons.
  final ValueChanged<Object>? onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final current = options.where((o) => '${o.value}' == '$selected');
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<Object>(
        showSelectedIcon: true,
        emptySelectionAllowed: true,
        segments: [
          for (final option in options)
            ButtonSegment<Object>(
              value: option.value,
              label: Text(option.label),
            ),
        ],
        selected: {for (final option in current) option.value},
        onSelectionChanged: onChanged == null
            ? null
            : (next) {
                if (next.isNotEmpty) {
                  onChanged!(next.first);
                }
              },
      ),
    );
  }
}
