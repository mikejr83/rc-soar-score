import 'package:flutter/material.dart';

import '../../services/configuration/setting_def.dart';
import 'choice_card.dart';
import 'config_chip.dart';
import 'config_note.dart';

/// Why one option of a [SettingRadioGroup] cannot be chosen, with a one-tap
/// fix that changes the other setting.
class BlockedOption {
  const BlockedOption({
    required this.value,
    required this.reason,
    required this.fixLabel,
    required this.onFix,
  });

  final Object value;
  final String reason;
  final String fixLabel;
  final VoidCallback onFix;
}

/// Radio options as cards: label, tag, explanation. The selected card has a
/// thick outline. A blocked option stays visible, disabled, with its reason.
class SettingRadioGroup extends StatelessWidget {
  const SettingRadioGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.blocked = const [],
  });

  final List<SettingOption> options;
  final Object? selected;

  /// `null` disables the whole group.
  final ValueChanged<Object>? onChanged;
  final List<BlockedOption> blocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = onChanged != null;
    return RadioGroup<Object>(
      groupValue: options
          .where((o) => '${o.value}' == '$selected')
          .map((o) => o.value)
          .firstOrNull,
      onChanged: (value) {
        if (value != null && enabled) {
          onChanged!(value);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in options) ...[
            _card(context, option, theme, scheme, enabled),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    SettingOption option,
    ThemeData theme,
    ColorScheme scheme,
    bool enabled,
  ) {
    final isSelected = '${option.value}' == '$selected';
    final block = blocked.where((b) => b.value == option.value).firstOrNull;
    final optionEnabled = enabled && block == null;
    return ChoiceCard(
      selected: isSelected,
      enabled: enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RadioListTile<Object>(
            value: option.value,
            enabled: optionEnabled,
            dense: true,
            contentPadding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
            title: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(option.label),
                if (option.tag != null)
                  ConfigChip.neutral(
                    context,
                    icon: Icons.star_outline,
                    text: option.tag!,
                  ),
              ],
            ),
            subtitle: option.help == null ? null : Text(option.help!),
          ),
          if (block != null && enabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 0, 12, 8),
              child: ConfigNote(
                icon: Icons.block,
                text: block.reason,
                tone: ConfigNoteTone.block,
                actionLabel: block.fixLabel,
                onAction: block.onFix,
              ),
            ),
        ],
      ),
    );
  }
}
