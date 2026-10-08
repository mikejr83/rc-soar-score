import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/configuration/config_impact.dart';
import '../../services/configuration/configuration_data.dart';
import '../../services/configuration/configuration_draft.dart';
import '../contest_list.dart';
import 'config_choice_row.dart';
import 'config_group_card.dart';
import 'config_switch_row.dart';
import 'config_value_row.dart';

/// The configuration cards of a contest, in the order of
/// `plan/ui/contest-administration/contest-workspace.md`.
///
/// Options that can be edited here change [draft] and call [onChanged];
/// the rest are shown for review. Everything is read-only when [editable] is
/// false or there is no saved configuration yet.
class ConfigurationGroups extends StatelessWidget {
  const ConfigurationGroups({
    super.key,
    required this.data,
    required this.draft,
    required this.editable,
    required this.onChanged,
  });

  final ConfigurationData data;
  final ConfigurationDraft? draft;
  final bool editable;
  final VoidCallback onChanged;

  static String _words(String json) => json
      .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ')
      .toLowerCase()
      .replaceFirstMapped(RegExp(r'^.'), (m) => m[0]!.toUpperCase());

  static String _yesNo(bool value) => value ? 'On' : 'Off';

  @override
  Widget build(BuildContext context) {
    final contest = data.contest;
    final draft = this.draft;
    final revision = data.configuration?.revisionNumber;
    final revisionLabel = revision == null
        ? 'No configuration saved yet'
        : 'Configuration revision $revision';
    final options = draft == null
        ? CoreOptions()
        : CoreOptions.fromMap({...draft.base.core, ...draft.build().core});
    final canEdit = editable && draft != null;

    Widget switchRow(String label, String key, bool value) => ConfigSwitchRow(
      label: label,
      value: value,
      onChanged: canEdit
          ? (next) {
              draft[key] = next;
              onChanged();
            }
          : null,
    );

    Widget choiceRow<T>(
      String label,
      String key,
      T value,
      Map<String, T> byJson,
    ) => ConfigChoiceRow<String>(
      label: label,
      value: byJson.entries.firstWhere((entry) => entry.value == value).key,
      options: {for (final json in byJson.keys) json: _words(json)},
      onChanged: canEdit
          ? (next) {
              draft[key] = next;
              onChanged();
            }
          : null,
    );

    final groups = <Widget>[
      ConfigGroupCard(
        title: 'Identity',
        children: [
          ConfigValueRow('Name', contest.name),
          ConfigValueRow('Dates', ContestList.contestDates(contest)),
          ConfigValueRow('Timezone', contest.timezone),
        ],
      ),
      ConfigGroupCard(
        title: 'Discipline and scoring rules',
        impact: ConfigImpact.scores,
        revisionLabel: revisionLabel,
        children: [
          ConfigValueRow('Group score', _words(options.groupScoreMode.json)),
          choiceRow('Rounding', 'rounding_mode', options.roundingMode, {
            for (final mode in RoundingMode.values) mode.json: mode,
          }),
          choiceRow('Decimal places', 'decimal_places', options.decimalPlaces, {
            for (var i = 0; i <= 3; i++) '$i': i,
          }),
          ConfigValueRow(
            'Drop after rounds',
            options.dropAfterRounds.isEmpty
                ? 'None'
                : options.dropAfterRounds.join(', '),
          ),
          switchRow(
            'Tiebreaker',
            'tiebreaker_enabled',
            options.tiebreakerEnabled,
          ),
        ],
      ),
      ConfigGroupCard(
        title: 'Participant options',
        impact: ConfigImpact.none,
        revisionLabel: revisionLabel,
        children: [
          switchRow('Classes', 'classes_enabled', options.classesEnabled),
          switchRow('Models', 'models_enabled', options.modelsEnabled),
          switchRow(
            'Participant numbers',
            'participant_numbers_enabled',
            options.participantNumbersEnabled,
          ),
          ConfigValueRow('Roles', _yesNo(options.rolesEnabled)),
          ConfigValueRow(
            'Teams',
            options.teamsEnabled
                ? '${options.teamPilotCount} pilots per team'
                : 'Off',
          ),
        ],
      ),
      ConfigGroupCard(
        title: 'Participants',
        children: [
          ConfigValueRow('Scoring pilots', '${data.scoringPilots}'),
          ConfigValueRow(
            'Other participants',
            '${data.participations.length - data.scoringPilots}',
          ),
        ],
      ),
      ConfigGroupCard(
        title: 'Draw options',
        impact: ConfigImpact.matrix,
        revisionLabel: revisionLabel,
        children: [
          ConfigValueRow('Draw mode', _words(options.drawMode.json)),
          choiceRow('Lanes', 'lane_mode', options.laneMode, {
            for (final mode in LaneMode.values) mode.json: mode,
          }),
          if (data.matrix == null)
            const ConfigValueRow('Matrix', 'Not drawn')
          else ...[
            ConfigValueRow('Matrix revision', '${data.matrix!.revisionNumber}'),
            ConfigValueRow(
              'Group size',
              data.matrix!.minGroupSize == data.matrix!.maxGroupSize
                  ? '${data.matrix!.minGroupSize}'
                  : '${data.matrix!.minGroupSize} to '
                        '${data.matrix!.maxGroupSize}',
            ),
            if (data.matrix!.maxDuplicateMatchups != null)
              ConfigValueRow(
                'Most repeated matchup',
                '${data.matrix!.maxDuplicateMatchups}',
              ),
            if (data.matrix!.unmetOpponents != null)
              ConfigValueRow(
                'Opponents never met',
                '${data.matrix!.unmetOpponents}',
              ),
          ],
        ],
      ),
      ConfigGroupCard(
        title: 'Scoring access',
        children: [
          ConfigValueRow(
            'Pilots can score',
            _words(contest.scoringAccess.name),
          ),
        ],
      ),
      ConfigGroupCard(
        title: 'Administration lock',
        children: [
          ConfigValueRow('Administration', _words(contest.adminLock.name)),
        ],
      ),
      ConfigGroupCard(
        title: 'Public update policy',
        impact: ConfigImpact.none,
        revisionLabel: revisionLabel,
        children: [
          choiceRow(
            'Results are published',
            'public_update_mode',
            options.publicUpdateMode,
            {for (final mode in PublicUpdateMode.values) mode.json: mode},
          ),
        ],
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups) ...[group, const SizedBox(height: 16)],
      ],
    );
  }
}
