import 'package:flutter/material.dart';

import '../../services/configuration/configuration_draft.dart';
import '../../services/configuration/setting_def.dart';
import '../../services/configuration/setting_keys.dart';
import '../../services/configuration/setting_values.dart';
import 'config_chip.dart';
import 'field_registry.dart';
import 'setting_notes.dart';
import 'setting_radio_group.dart';
import 'setting_row.dart';
import 'setting_segmented.dart';
import 'setting_text_input.dart';
import 'setting_toggle.dart';

/// One setting of the page: its row with tags, control and notes, wired to
/// the [draft].
class SettingField extends StatelessWidget {
  const SettingField({
    super.key,
    required this.def,
    required this.draft,
    required this.registry,
    required this.editable,
    required this.onChanged,
  });

  final SettingDef def;
  final ConfigurationDraft draft;
  final FieldRegistry registry;

  /// False while the page is read-only or a save is running.
  final bool editable;

  /// Called after the draft changed.
  final VoidCallback onChanged;

  void _set(Object? value) {
    draft.set(def.key, value);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final key = def.key;
    final effect = draft.effectOf(def);
    final locked = effect.fixed;
    final enabled = editable && !locked;
    final change = draft.changeOf(key);
    final error = draft.errors[key];
    final house =
        def.official != null &&
        SettingValues.canon(def, draft[key]) !=
            SettingValues.canon(def, def.official);
    final mixed = def.section.mixed;

    return KeyedSubtree(
      key: registry.rowKey(key),
      child: SettingRow(
        heading: def.heading,
        headingHelp: def.headingHelp,
        label: def.label,
        help: def.help,
        required: def.required,
        dimmed: !enabled && editable,
        tags: [
          if (error != null) ConfigChip.error(context),
          if (change != null) ConfigChip.unsaved(context),
          if (house) ConfigChip.houseRule(context),
          if (locked && editable && effect.reason != null)
            ConfigChip.fixed(context),
          if (mixed)
            ConfigChip.neutral(
              context,
              icon: def.kind.icon,
              text: def.kind.label,
              dashed: true,
            ),
        ],
        control: _control(context, enabled, error != null),
        notes: SettingNotes.of(
          draft: draft,
          def: def,
          editable: editable,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _control(BuildContext context, bool enabled, bool hasError) {
    final key = def.key;
    final value = draft[key];
    final focus = registry.focusNode(key);
    switch (def.type) {
      case SettingType.text:
        return SettingTextInput(
          value: '${value ?? ''}',
          focusNode: focus,
          enabled: enabled,
          hasError: hasError,
          semanticLabel: def.label,
          onChanged: _set,
        );
      case SettingType.date:
        return SettingTextInput(
          value: '${value ?? ''}',
          focusNode: focus,
          enabled: enabled,
          hasError: hasError,
          semanticLabel: def.label,
          maxWidth: 240,
          readOnly: true,
          placeholder: 'yyyy-mm-dd',
          suffixIcon: const Icon(Icons.calendar_today_outlined),
          onTap: enabled ? () => _pickDate(context) : null,
          onChanged: _set,
        );
      case SettingType.integer || SettingType.decimal || SettingType.duration:
        return SettingTextInput(
          value: SettingValues.fieldText(def, value),
          focusNode: focus,
          enabled: enabled,
          hasError: hasError,
          semanticLabel: def.label,
          unit: def.unit,
          maxWidth: 240,
          placeholder: def.type == SettingType.duration
              ? 'mm:ss'
              : def.placeholder,
          keyboardType: def.type == SettingType.decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          onChanged: _set,
        );
      case SettingType.toggle:
        return SettingToggle(
          value: value == true,
          focusNode: focus,
          label: def.label,
          onChanged: enabled ? _set : null,
        );
      case SettingType.segmented:
        return SettingSegmented(
          options: def.options,
          selected: value,
          onChanged: enabled ? _set : null,
        );
      case SettingType.radio:
        return SettingRadioGroup(
          options: def.options,
          selected: value,
          onChanged: enabled ? _set : null,
          blocked: _blockedOptions(),
        );
      case SettingType.select || SettingType.readOnly:
        return _ReadOnlyValue(
          text: def.readOnlyValue ?? '${value ?? ''}',
          detail: def.readOnlyDetail,
        );
    }
  }

  List<BlockedOption> _blockedOptions() {
    if (def.key != SettingKeys.drawMode) {
      return const [];
    }
    final protectedTeams =
        draft[SettingKeys.teams] == true &&
        draft[SettingKeys.teamProtection] == true;
    if (!protectedTeams || draft[def.key] == SettingKeys.seeded) {
      return const [];
    }
    return [
      BlockedOption(
        value: SettingKeys.seeded,
        reason:
            'Not available while team protection is on. Seeded groups are '
            'formed by score, so teammates may have to fly together.',
        fixLabel: 'Turn off team protection',
        onFix: () {
          draft.setAll({
            SettingKeys.teamProtection: false,
            SettingKeys.drawMode: SettingKeys.seeded,
          });
          onChanged();
        },
      ),
    ];
  }

  Future<void> _pickDate(BuildContext context) async {
    final current = DateTime.tryParse('${draft[def.key] ?? ''}');
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _set(
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}',
      );
    }
  }
}

class _ReadOnlyValue extends StatelessWidget {
  const _ReadOnlyValue({required this.text, this.detail});

  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: theme.textTheme.bodyLarge),
                if (detail != null)
                  Text(
                    detail!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
