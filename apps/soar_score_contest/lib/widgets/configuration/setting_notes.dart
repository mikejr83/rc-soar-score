import 'package:flutter/material.dart';

import '../../services/configuration/configuration_draft.dart';
import '../../services/configuration/setting_def.dart';
import '../../services/configuration/setting_keys.dart';
import '../../services/configuration/setting_values.dart';
import 'config_note.dart';

/// The notes under a setting's control, in reading order: the error, why it
/// is fixed or blocked, house-rule and conversion hints, and what saving the
/// change will do.
abstract final class SettingNotes {
  static List<Widget> of({
    required ConfigurationDraft draft,
    required SettingDef def,
    required bool editable,
    required VoidCallback onChanged,
  }) {
    final key = def.key;
    final value = draft[key];
    final effect = draft.effectOf(def);
    final error = draft.errors[key];
    final change = draft.changeOf(key);
    final fixed = !editable || effect.fixed;
    final notes = <Widget>[];

    void set(Map<String, Object?> next) {
      draft.setAll(next);
      onChanged();
    }

    if (error != null) {
      notes.add(
        ConfigNote(
          noteId: ValueKey('error-$key'),
          icon: Icons.error_outline,
          text: error,
          tone: ConfigNoteTone.error,
        ),
      );
    }
    if (key == SettingKeys.teamProtection &&
        draft[SettingKeys.drawMode] == SettingKeys.seeded &&
        editable) {
      notes.add(
        ConfigNote(
          icon: Icons.block,
          text:
              'Not available with Seeded Man on Man. Seeded groups are formed '
              'by score, so teammates may have to fly together.',
          tone: ConfigNoteTone.block,
          actionLabel: fixed ? null : 'Use Man on Man instead',
          actionIcon: Icons.swap_horiz,
          onAction: () => set({SettingKeys.drawMode: SettingKeys.standard}),
        ),
      );
    }
    if (def.official != null &&
        SettingValues.canon(def, value) !=
            SettingValues.canon(def, def.official)) {
      final label = draft.catalog.defaultLabel;
      final official = SettingValues.display(def, def.official);
      final seconds = def.type == SettingType.duration
          ? ' (${SettingValues.parseDuration(def.official)} s)'
          : '';
      notes.add(
        ConfigNote(
          icon: Icons.home_outlined,
          text: '$label: $official$seconds.',
          tone: ConfigNoteTone.block,
          actionLabel: fixed ? null : 'Reset to $label',
          actionIcon: Icons.restart_alt,
          onAction: () => set({key: def.official}),
        ),
      );
    }
    if (def.type == SettingType.duration && error == null) {
      final seconds = SettingValues.parseDuration(value);
      if (seconds != null) {
        notes.add(
          ConfigNote(
            icon: Icons.timer_outlined,
            text:
                'Entered as minutes:seconds. '
                '${SettingValues.formatDuration(seconds)} = $seconds s.',
          ),
        );
      }
    }
    if (key == SettingKeys.decimalPlaces) {
      notes.add(_example(draft));
    }
    if (key == SettingKeys.drops) {
      notes.addAll(_dropNotes(draft));
    }
    if (key == SettingKeys.teamProtection &&
        draft[key] == true &&
        draft[SettingKeys.drawMode] != SettingKeys.seeded) {
      notes.add(
        const ConfigNote(
          icon: Icons.info_outline,
          text:
              'Groups per round, set on the Matrix page, must be at least the '
              'size of the largest team.',
        ),
      );
    }
    if (key == SettingKeys.participantNumbers && draft.phase.isDrawn) {
      notes.add(
        const ConfigNote(
          icon: Icons.info_outline,
          text: 'Numbers assigned at the draw don’t change.',
        ),
      );
    }
    if ((key == SettingKeys.drop1 || key == SettingKeys.drop2) &&
        !draft.phase.isDrawn &&
        error == null) {
      notes.add(
        const ConfigNote(
          icon: Icons.info_outline,
          text: 'Checked against the rounds drawn on the Matrix page.',
        ),
      );
    }
    for (final cleared in draft.clearedBy(key)) {
      notes.add(
        ConfigNote(
          icon: Icons.delete_sweep_outlined,
          text:
              '${cleared.def.label} '
              '(${SettingValues.display(cleared.def, draft.saved[cleared.def.key])}) '
              'is hidden and will be cleared when you save.',
        ),
      );
    }
    if (change != null && !change.cleared) {
      notes.add(
        ConfigNote(
          icon: Icons.history,
          text: 'Saved: ${SettingValues.display(def, draft.saved[key])}',
          actionLabel: 'Undo',
          actionIcon: Icons.undo,
          onAction: () => set({key: draft.saved[key]}),
        ),
      );
      if (effect.outdatesMatrix) {
        notes.add(
          const ConfigNote(
            icon: Icons.sync_problem,
            text: 'Saving makes the drawn matrix out of date.',
            tone: ConfigNoteTone.warning,
          ),
        );
      }
      if (effect.recalculates) {
        notes.add(
          const ConfigNote(
            icon: Icons.calculate_outlined,
            text: 'Saving recalculates all results.',
          ),
        );
      }
    }
    return notes;
  }

  static Widget _example(ConfigurationDraft draft) {
    final places = SettingValues.parseNumber(draft[SettingKeys.decimalPlaces]);
    final truncate = draft[SettingKeys.roundingMode] == 'Truncate';
    const sample = 987.654;
    final d = places?.toInt() ?? 1;
    var scale = 1.0;
    for (var i = 0; i < d; i++) {
      scale *= 10;
    }
    final result = truncate
        ? (((sample * scale).floor()) / scale).toStringAsFixed(d)
        : sample.toStringAsFixed(d);
    return ConfigNote(
      icon: Icons.functions,
      tone: ConfigNoteTone.block,
      text:
          'Example: 987.654 → $result ${truncate ? '(truncated)' : '(rounded)'}',
    );
  }

  static List<Widget> _dropNotes(ConfigurationDraft draft) {
    final drops =
        SettingValues.parseNumber(draft[SettingKeys.drops])?.toInt() ?? 0;
    String round(String key) {
      final value = '${draft[key] ?? ''}'.trim();
      return value.isEmpty ? '…' : value;
    }

    return [
      ConfigNote(
        icon: Icons.playlist_remove,
        tone: ConfigNoteTone.block,
        text: drops == 0
            ? 'No rounds are dropped.'
            : drops == 1
            ? 'Drop the worst round after round ${round(SettingKeys.drop1)}.'
            : 'Drop the worst round after round ${round(SettingKeys.drop1)}, '
                  'and a second after round ${round(SettingKeys.drop2)}.',
      ),
      if (drops > 0 && draft['d_motor_restart_mode'] == 'non_droppable')
        const ConfigNote(
          icon: Icons.info_outline,
          text:
              'A round with a motor restart can’t be dropped (Motor restart '
              'mode: Allowed, not dropped).',
        ),
    ];
  }
}
