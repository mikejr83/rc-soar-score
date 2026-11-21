import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../services/configuration/configuration_draft.dart';
import '../../services/configuration/house_rules.dart';
import '../../services/configuration/setting_def.dart';
import '../../services/configuration/setting_keys.dart';
import '../../services/configuration/setting_values.dart';
import 'config_note.dart';

/// The notes under a setting's control, in reading order: the error, why it
/// is fixed or blocked, house-rule and conversion hints, and what saving the
/// change will do.
abstract final class SettingNotes {
  static List<Widget> of({
    required AppLocalizations l10n,
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
          text: l10n.configNoteTeamProtectionSeeded,
          tone: ConfigNoteTone.block,
          actionLabel: fixed ? null : l10n.configNoteUseManOnMan,
          actionIcon: Icons.swap_horiz,
          onAction: () => set({SettingKeys.drawMode: SettingKeys.standard}),
        ),
      );
    }
    if (HouseRules.isHouseRule(def, value)) {
      final label = draft.catalog.defaultLabel;
      final official = SettingValues.display(def, def.official);
      final seconds = def.type == SettingType.duration
          ? ' (${SettingValues.parseDuration(def.official)} s)'
          : '';
      notes.add(
        ConfigNote(
          icon: Icons.home_outlined,
          text: l10n.configNoteHouseRule(label, official, seconds),
          tone: ConfigNoteTone.block,
          actionLabel: fixed ? null : l10n.configNoteResetTo(label),
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
            text: l10n.configNoteDuration(
              SettingValues.formatDuration(seconds),
              seconds,
            ),
          ),
        );
      }
    }
    if (key == SettingKeys.decimalPlaces) {
      notes.add(_example(l10n, draft));
    }
    if (key == SettingKeys.drops) {
      notes.addAll(_dropNotes(l10n, draft));
    }
    if (key == SettingKeys.teamProtection &&
        draft[key] == true &&
        draft[SettingKeys.drawMode] != SettingKeys.seeded) {
      notes.add(
        ConfigNote(
          icon: Icons.info_outline,
          text: l10n.configNoteTeamProtectionSize,
        ),
      );
    }
    if (key == SettingKeys.participantNumbers && draft.phase.isDrawn) {
      notes.add(
        ConfigNote(icon: Icons.info_outline, text: l10n.configNoteNumbersFixed),
      );
    }
    if ((key == SettingKeys.drop1 || key == SettingKeys.drop2) &&
        !draft.phase.isDrawn &&
        error == null) {
      notes.add(
        ConfigNote(icon: Icons.info_outline, text: l10n.configNoteDropsChecked),
      );
    }
    for (final cleared in draft.clearedBy(key)) {
      notes.add(
        ConfigNote(
          icon: Icons.delete_sweep_outlined,
          text: l10n.configNoteCleared(
            cleared.def.label,
            SettingValues.display(cleared.def, draft.saved[cleared.def.key]),
          ),
        ),
      );
    }
    if (change != null && !change.cleared) {
      notes.add(
        ConfigNote(
          icon: Icons.history,
          text: l10n.configNoteSaved(
            SettingValues.display(def, draft.saved[key]),
          ),
          actionLabel: l10n.commonUndo,
          actionIcon: Icons.undo,
          onAction: () => set({key: draft.saved[key]}),
        ),
      );
      if (effect.outdatesMatrix) {
        notes.add(
          ConfigNote(
            icon: Icons.sync_problem,
            text: l10n.configLandingOutdatesMatrix,
            tone: ConfigNoteTone.warning,
          ),
        );
      }
      if (effect.recalculates) {
        notes.add(
          ConfigNote(
            icon: Icons.calculate_outlined,
            text: l10n.configNoteRecalculates,
          ),
        );
      }
    }
    return notes;
  }

  static Widget _example(AppLocalizations l10n, ConfigurationDraft draft) {
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
      text: l10n.configNoteExample(
        result,
        truncate ? l10n.configNoteTruncated : l10n.configNoteRounded,
      ),
    );
  }

  static List<Widget> _dropNotes(
    AppLocalizations l10n,
    ConfigurationDraft draft,
  ) {
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
            ? l10n.configNoteNoDrops
            : drops == 1
            ? l10n.configNoteDropOne(round(SettingKeys.drop1))
            : l10n.configNoteDropTwo(
                round(SettingKeys.drop1),
                round(SettingKeys.drop2),
              ),
      ),
      if (drops > 0 && draft['d_motor_restart_mode'] == 'non_droppable')
        ConfigNote(icon: Icons.info_outline, text: l10n.configNoteMotorRestart),
    ];
  }
}
