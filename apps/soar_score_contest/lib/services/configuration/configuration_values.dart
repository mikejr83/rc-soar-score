import 'package:intl/intl.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'configuration_draft.dart';
import 'setting_catalog.dart';
import 'setting_def.dart';
import 'setting_keys.dart';
import 'setting_values.dart';

/// What the draft saves: the configuration and the landing table.
class ConfigurationToSave {
  const ConfigurationToSave({
    required this.config,
    required this.landingTableId,
  });

  final ContestConfig config;
  final Id? landingTableId;
}

/// Converting between the saved contest and configuration and the flat
/// values of the draft.
abstract final class ConfigurationValues {
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  /// The values of [contest] and [revision] by setting key.
  static Map<String, Object?> fromSaved(
    Contest contest,
    ContestConfigurationRevision revision,
    SettingCatalog catalog,
  ) {
    final core = revision.config.coreOptions;
    final discipline = revision.config.discipline;
    final drops = core.dropAfterRounds;
    return {
      SettingKeys.name: contest.name,
      SettingKeys.start: _dateFormat.format(contest.startDateTime),
      SettingKeys.end: _dateFormat.format(contest.endDateTime),
      SettingKeys.timezone: contest.timezone,
      SettingKeys.host: contest.host ?? '',
      SettingKeys.city: contest.city ?? '',
      SettingKeys.state: contest.state ?? '',
      SettingKeys.country: contest.country ?? '',
      for (final def in catalog.disciplineSettings)
        def.key:
            discipline[def.key.substring(
              SettingKeys.disciplinePrefix.length,
            )] ??
            def.official,
      SettingKeys.landingTable: revision.landingTableId?.value,
      SettingKeys.groupScoreMode: core.groupScoreMode.json,
      SettingKeys.roundingMode: core.roundingMode.json,
      SettingKeys.decimalPlaces: core.decimalPlaces,
      SettingKeys.drops: drops.length,
      SettingKeys.drop1: drops.isNotEmpty ? drops[0] : '',
      SettingKeys.drop2: drops.length > 1 ? drops[1] : '',
      SettingKeys.tiebreaker: core.tiebreakerEnabled,
      SettingKeys.teamPilotCount: core.teamPilotCount ?? '',
      SettingKeys.teams: core.teamsEnabled,
      SettingKeys.roles: core.rolesEnabled,
      SettingKeys.classes: core.classesEnabled,
      SettingKeys.models: core.modelsEnabled,
      SettingKeys.participantNumbers: core.participantNumbersEnabled,
      SettingKeys.drawMode: core.drawMode.json,
      SettingKeys.preliminaryRounds: core.preliminaryRounds ?? '',
      SettingKeys.intendedTotalRounds: core.intendedTotalRounds ?? '',
      SettingKeys.teamProtection: core.teamProtection,
      SettingKeys.allowBackToBack: core.allowBackToBack,
      SettingKeys.laneMode: core.laneMode.json,
      SettingKeys.publicUpdateMode: core.publicUpdateMode.json,
      SettingKeys.reviewRequests: core.reviewRequestsEnabled,
    };
  }

  /// The configuration to save for [draft], as an edit of [base]. Options a
  /// setting hides (team options without teams, seeding options without
  /// the seeded draw) are left out.
  static ConfigurationToSave toSave(
    ConfigurationDraft draft,
    ContestConfigurationRevision base,
  ) {
    num? number(String key) => SettingValues.parseNumber(draft[key]);
    int? whole(String key) => number(key)?.toInt();
    bool flag(String key) => draft[key] == true;

    final core = Map<String, Object?>.of(base.config.core);
    void putOrRemove(String key, Object? value) =>
        value == null ? core.remove(key) : core[key] = value;

    final teams = flag(SettingKeys.teams);
    final seeded = draft[SettingKeys.drawMode] == SettingKeys.seeded;
    final drops = whole(SettingKeys.drops) ?? 0;
    core
      ..[SettingKeys.teams] = teams
      ..[SettingKeys.roles] = flag(SettingKeys.roles)
      ..[SettingKeys.drawMode] = draft[SettingKeys.drawMode]
      ..[SettingKeys.laneMode] = draft[SettingKeys.laneMode]
      ..[SettingKeys.allowBackToBack] = flag(SettingKeys.allowBackToBack)
      ..[SettingKeys.groupScoreMode] = draft[SettingKeys.groupScoreMode]
      ..[SettingKeys.roundingMode] = draft[SettingKeys.roundingMode]
      ..[SettingKeys.decimalPlaces] = whole(SettingKeys.decimalPlaces)
      ..[SettingKeys.tiebreaker] = flag(SettingKeys.tiebreaker)
      ..[SettingKeys.classes] = flag(SettingKeys.classes)
      ..[SettingKeys.models] = flag(SettingKeys.models)
      ..[SettingKeys.participantNumbers] = flag(SettingKeys.participantNumbers)
      ..[SettingKeys.reviewRequests] = flag(SettingKeys.reviewRequests)
      ..[SettingKeys.publicUpdateMode] = draft[SettingKeys.publicUpdateMode]
      ..[SettingKeys.teamProtection] = teams && flag(SettingKeys.teamProtection)
      ..['drop_after_rounds'] = [
        if (drops >= 1) whole(SettingKeys.drop1),
        if (drops >= 2) whole(SettingKeys.drop2),
      ];
    putOrRemove(
      SettingKeys.teamPilotCount,
      teams ? whole(SettingKeys.teamPilotCount) : null,
    );
    putOrRemove(
      SettingKeys.preliminaryRounds,
      seeded ? whole(SettingKeys.preliminaryRounds) : null,
    );
    putOrRemove(
      SettingKeys.intendedTotalRounds,
      seeded ? whole(SettingKeys.intendedTotalRounds) : null,
    );

    final discipline = Map<String, Object?>.of(base.config.discipline);
    for (final def in draft.catalog.disciplineSettings) {
      discipline[def.key.substring(SettingKeys.disciplinePrefix.length)] =
          _disciplineValue(def, draft[def.key]);
    }
    final table = draft[SettingKeys.landingTable];
    return ConfigurationToSave(
      config: ContestConfig(core: core, discipline: discipline),
      landingTableId: table == null ? null : Id.parse('$table'),
    );
  }

  static Object? _disciplineValue(SettingDef def, Object? value) =>
      switch (def.type) {
        SettingType.duration => SettingValues.parseDuration(value),
        SettingType.integer => SettingValues.parseNumber(value)?.toInt(),
        SettingType.decimal => SettingValues.parseNumber(value)?.toDouble(),
        SettingType.toggle => value == true,
        _ => value,
      };

  /// The request that saves the changed contest details of [draft].
  static UpdateContestRequest toUpdate(
    ConfigurationDraft draft,
    Contest contest,
  ) {
    String? text(String key) {
      final value = '${draft[key] ?? ''}'.trim();
      return value.isEmpty ? null : value;
    }

    DateTime day(String key, DateTime current) {
      if (draft[key] == draft.saved[key]) {
        return current;
      }
      final date = DateTime.parse('${draft[key]}');
      return DateTime.utc(date.year, date.month, date.day, 12);
    }

    return UpdateContestRequest(
      baseRevision: contest.revision,
      name: text(SettingKeys.name)!,
      startDateTime: day(SettingKeys.start, contest.startDateTime),
      endDateTime: day(SettingKeys.end, contest.endDateTime),
      host: text(SettingKeys.host),
      city: text(SettingKeys.city),
      state: text(SettingKeys.state),
      country: text(SettingKeys.country),
    );
  }
}
