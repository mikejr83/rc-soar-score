import 'package:soar_score_core/soar_score_core.dart';

import 'discipline_label.dart';
import 'discipline_settings.dart';
import 'section_id.dart';
import 'setting_def.dart';
import 'setting_keys.dart';
import 'setting_kind.dart';

/// Every setting of the configuration page, in page order.
class SettingCatalog {
  SettingCatalog._(this.settings, this.profile)
    : byKey = {for (final setting in settings) setting.key: setting};

  /// The catalog for a contest of [profile]; without a known profile the
  /// discipline section has no options to edit.
  factory SettingCatalog.forProfile(DisciplineProfileWithRules? profile) {
    final defaults = {
      ..._platformDefaults,
      ...?profile?.profile.defaultOptions,
    };
    final defaultLabel = profile == null
        ? 'Default'
        : DisciplineLabel.defaultOf(profile.profile);
    SettingOption option(Object value, String label, String help, String key) =>
        SettingOption(
          value,
          label,
          help: help,
          tag: defaults[key] == value ? defaultLabel : null,
        );

    return SettingCatalog._([
      ..._details,
      if (profile != null) ...[
        SettingDef(
          key: 'discipline',
          section: SectionId.discipline,
          kind: SettingKind.rules,
          label: 'Discipline',
          help:
              'Set when the contest was created and can’t change. To fly '
              'another discipline, create a new contest.',
          type: SettingType.readOnly,
          readOnlyValue: DisciplineLabel.of(profile.profile),
        ),
        ...DisciplineSettings.of(profile),
      ],
      SettingDef(
        key: SettingKeys.landingTable,
        section: SectionId.landing,
        kind: SettingKind.rules,
        label: 'Landing table',
        help: 'The distance-to-points lookup scorers use for landing bonuses.',
        type: SettingType.readOnly,
      ),
      SettingDef(
        key: SettingKeys.groupScoreMode,
        section: SectionId.scoring,
        kind: SettingKind.recalc,
        label: 'Group score',
        help: 'How each flight becomes a group score.',
        type: SettingType.radio,
        options: [
          option(
            'Raw',
            'Raw',
            'Scores are the raw flight points.',
            SettingKeys.groupScoreMode,
          ),
          option(
            'Normalized',
            'Normalized',
            'The group winner gets 1000; other scores are scaled to it.',
            SettingKeys.groupScoreMode,
          ),
          option(
            'Time',
            'Time',
            'Flight time is normalized to the group winner, then landing '
                'bonuses are added.',
            SettingKeys.groupScoreMode,
          ),
        ],
      ),
      const SettingDef(
        key: SettingKeys.roundingMode,
        section: SectionId.scoring,
        kind: SettingKind.recalc,
        label: 'Rounding',
        help: 'How scores are cut to the chosen number of decimal places.',
        type: SettingType.segmented,
        options: [
          SettingOption('Round', 'Round'),
          SettingOption('Truncate', 'Truncate'),
        ],
      ),
      const SettingDef(
        key: SettingKeys.decimalPlaces,
        section: SectionId.scoring,
        kind: SettingKind.recalc,
        label: 'Decimal places',
        help: 'Decimal places kept for every score.',
        type: SettingType.segmented,
        options: [
          SettingOption(0, '0'),
          SettingOption(1, '1'),
          SettingOption(2, '2'),
          SettingOption(3, '3'),
        ],
      ),
      const SettingDef(
        key: SettingKeys.drops,
        section: SectionId.scoring,
        kind: SettingKind.recalc,
        label: 'Drop worst rounds',
        help:
            'Leave each pilot’s worst rounds out of their total once enough '
            'rounds are flown.',
        type: SettingType.segmented,
        options: [
          SettingOption(0, 'None'),
          SettingOption(1, 'One'),
          SettingOption(2, 'Two'),
        ],
      ),
      const SettingDef(
        key: SettingKeys.drop1,
        section: SectionId.scoring,
        kind: SettingKind.recalc,
        label: 'First drop after round',
        help: 'The worst round is dropped once this round is flown.',
        type: SettingType.integer,
        min: 1,
        max: 99,
      ),
      const SettingDef(
        key: SettingKeys.drop2,
        section: SectionId.scoring,
        kind: SettingKind.recalc,
        label: 'Second drop after round',
        help:
            'A second worst round is dropped after this round. Must be later '
            'than the first.',
        type: SettingType.integer,
        min: 1,
        max: 99,
      ),
      const SettingDef(
        key: SettingKeys.tiebreaker,
        section: SectionId.scoring,
        kind: SettingKind.recalc,
        label: 'Tie-breakers',
        help:
            'Break tied totals with the discipline’s tie-break rule instead of '
            'sharing the place.',
        type: SettingType.toggle,
      ),
      const SettingDef(
        key: SettingKeys.teamPilotCount,
        section: SectionId.scoring,
        kind: SettingKind.recalc,
        label: 'Team score: count the best',
        help:
            'A team’s score adds its best pilot scores. A team with fewer '
            'pilots counts them all.',
        type: SettingType.integer,
        unit: 'pilots',
        min: 1,
        max: 99,
        required: true,
      ),
      const SettingDef(
        key: SettingKeys.teams,
        section: SectionId.participantOptions,
        kind: SettingKind.structural,
        label: 'Teams',
        help:
            'Put pilots in teams on the Participants page. Adds team score and '
            'team protection.',
        type: SettingType.toggle,
      ),
      const SettingDef(
        key: SettingKeys.roles,
        section: SectionId.participantOptions,
        kind: SettingKind.structural,
        label: 'Roles',
        help:
            'Participants can have roles other than Pilot, such as timer or '
            'CD.',
        type: SettingType.toggle,
      ),
      const SettingDef(
        key: SettingKeys.classes,
        section: SectionId.participantOptions,
        kind: SettingKind.present,
        label: 'Classes',
        help: 'Give each pilot a class, used only in reports.',
        type: SettingType.toggle,
      ),
      const SettingDef(
        key: SettingKeys.models,
        section: SectionId.participantOptions,
        kind: SettingKind.present,
        label: 'Models',
        help: 'Track the models each pilot flies.',
        type: SettingType.toggle,
      ),
      const SettingDef(
        key: SettingKeys.participantNumbers,
        section: SectionId.participantOptions,
        kind: SettingKind.present,
        label: 'Participant numbers',
        help:
            'Shows each participant’s number. Numbers are assigned by the '
            'draw; this only shows or hides them.',
        type: SettingType.toggle,
      ),
      SettingDef(
        key: SettingKeys.drawMode,
        section: SectionId.draw,
        kind: SettingKind.structural,
        label: 'Draw mode',
        help: 'How pilots are put into groups each round.',
        type: SettingType.radio,
        options: [
          option(
            SettingKeys.standard,
            'Man on Man',
            'Maximises the variety of opponents across rounds.',
            SettingKeys.drawMode,
          ),
          option(
            SettingKeys.seeded,
            'Seeded Man on Man',
            'After the preliminary rounds, each new round groups pilots with '
                'similar scores.',
            SettingKeys.drawMode,
          ),
        ],
      ),
      const SettingDef(
        key: SettingKeys.preliminaryRounds,
        section: SectionId.draw,
        kind: SettingKind.structural,
        label: 'Preliminary rounds',
        help: 'Man on Man rounds flown before seeding starts.',
        type: SettingType.integer,
        unit: 'rounds',
        min: 1,
        max: 20,
      ),
      const SettingDef(
        key: SettingKeys.intendedTotalRounds,
        section: SectionId.draw,
        kind: SettingKind.present,
        label: 'Intended total rounds',
        help:
            'Display only. Shown as “Round 4 of 8” on score cards and the '
            'public site. It doesn’t affect the draw.',
        type: SettingType.integer,
        unit: 'rounds',
        min: 1,
        max: 99,
        placeholder: 'Not set',
      ),
      const SettingDef(
        key: SettingKeys.teamProtection,
        section: SectionId.draw,
        kind: SettingKind.structural,
        label: 'Team protection',
        help: 'Pilots on the same team never fly in the same group.',
        type: SettingType.toggle,
      ),
      const SettingDef(
        key: SettingKeys.laneMode,
        section: SectionId.draw,
        kind: SettingKind.structural,
        label: 'Lanes',
        help: 'Random gives each pilot a random lane (peg) within their group.',
        type: SettingType.segmented,
        options: [
          SettingOption('None', 'None'),
          SettingOption('Random', 'Random'),
        ],
      ),
      SettingDef(
        key: SettingKeys.publicUpdateMode,
        section: SectionId.publicUpdates,
        kind: SettingKind.present,
        label: 'Public update policy',
        help: 'When new scores appear on the public site.',
        type: SettingType.radio,
        options: [
          option(
            'Automatic',
            'Automatic',
            'The public site updates as each score is accepted.',
            SettingKeys.publicUpdateMode,
          ),
          option(
            'RoundCompletion',
            'At round completion',
            'The public site updates when every group in a round is scored.',
            SettingKeys.publicUpdateMode,
          ),
          option(
            'Manual',
            'Manual',
            'The public site updates only when you publish.',
            SettingKeys.publicUpdateMode,
          ),
        ],
      ),
      const SettingDef(
        key: SettingKeys.reviewRequests,
        section: SectionId.publicUpdates,
        kind: SettingKind.present,
        label: 'Review requests',
        help: 'Participants can ask for a review of a submitted score.',
        type: SettingType.toggle,
      ),
    ], profile);
  }

  /// The defaults of the options that choose between cards, unless the
  /// profile suggests another.
  static const _platformDefaults = {
    SettingKeys.drawMode: SettingKeys.standard,
    SettingKeys.publicUpdateMode: 'RoundCompletion',
  };

  static const _details = [
    SettingDef(
      key: SettingKeys.name,
      section: SectionId.details,
      kind: SettingKind.details,
      label: 'Contest name',
      help: 'Shown on score cards, reports and the public site.',
      type: SettingType.text,
      required: true,
    ),
    SettingDef(
      key: SettingKeys.start,
      section: SectionId.details,
      kind: SettingKind.details,
      label: 'Start date',
      help: 'First flying day.',
      type: SettingType.date,
      required: true,
    ),
    SettingDef(
      key: SettingKeys.end,
      section: SectionId.details,
      kind: SettingKind.details,
      label: 'End date',
      help: 'Last flying day. Use the start date for a one-day contest.',
      type: SettingType.date,
      required: true,
    ),
    SettingDef(
      key: SettingKeys.timezone,
      section: SectionId.details,
      kind: SettingKind.details,
      label: 'Timezone',
      help:
          'Set when the contest was created. Round times and the public site '
          'use it.',
      type: SettingType.readOnly,
    ),
    SettingDef(
      key: SettingKeys.host,
      section: SectionId.details,
      kind: SettingKind.details,
      label: 'Host and venue',
      help: 'The organising club and the flying field.',
      type: SettingType.text,
    ),
    SettingDef(
      key: SettingKeys.city,
      section: SectionId.details,
      kind: SettingKind.details,
      label: 'City',
      help: 'Part of the venue line on the public site.',
      type: SettingType.text,
    ),
    SettingDef(
      key: SettingKeys.state,
      section: SectionId.details,
      kind: SettingKind.details,
      label: 'State or province',
      help: 'Part of the venue line on the public site.',
      type: SettingType.text,
    ),
    SettingDef(
      key: SettingKeys.country,
      section: SectionId.details,
      kind: SettingKind.details,
      label: 'Country',
      help: 'Part of the venue line on the public site.',
      type: SettingType.text,
    ),
  ];

  /// The profile the contest flies; `null` when it is not a system profile.
  final DisciplineProfileWithRules? profile;

  /// `F5J default`: what a profile's own value is called on the page.
  String get defaultLabel =>
      profile == null ? 'Default' : DisciplineLabel.defaultOf(profile!.profile);

  final List<SettingDef> settings;
  final Map<String, SettingDef> byKey;

  /// The editable discipline options.
  Iterable<SettingDef> get disciplineSettings =>
      settings.where((s) => SettingKeys.isDiscipline(s.key));

  List<SettingDef> inSection(SectionId id) => [
    for (final setting in settings)
      if (setting.section == id) setting,
  ];

  /// Whether [key] applies given the current [values]: team options need
  /// teams, seeding options need the seeded draw, and so on.
  static bool isVisible(String key, Object? Function(String key) values) =>
      switch (key) {
        SettingKeys.teamPilotCount ||
        SettingKeys.teamProtection => values(SettingKeys.teams) == true,
        SettingKeys.preliminaryRounds || SettingKeys.intendedTotalRounds =>
          values(SettingKeys.drawMode) == SettingKeys.seeded,
        SettingKeys.drop1 => _drops(values) >= 1,
        SettingKeys.drop2 => _drops(values) == 2,
        _ => true,
      };

  static int _drops(Object? Function(String key) values) {
    final drops = values(SettingKeys.drops);
    return drops is num ? drops.toInt() : int.tryParse('$drops') ?? 0;
  }
}
