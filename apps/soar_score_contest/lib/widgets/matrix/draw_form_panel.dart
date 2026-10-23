import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/configuration/draw_readiness.dart';
import '../../services/matrix/draw_form_check.dart';
import '../../services/matrix/draw_form_controller.dart';
import '../../services/matrix/matrix_page_data.dart';
import 'draw_action_row.dart';
import 'draw_advanced_section.dart';
import 'draw_config_rows.dart';
import 'draw_number_field.dart';
import 'group_size_preview.dart';
import '../page_states/page_banner.dart';
import 'matrix_banner.dart';

/// The empty state and the first-draw form (mode 1 of the matrix page).
///
/// It is shown disabled with the reason beside the button, never hidden,
/// when the draw is not allowed.
class DrawFormPanel extends StatelessWidget {
  const DrawFormPanel({
    super.key,
    required this.data,
    required this.controller,
    required this.busy,
    required this.blocker,
    required this.onDraw,
    required this.onOpenConfiguration,
    required this.onFix,
    required this.onReload,
    this.rejection,
    this.networkFailure = false,
    this.conflict = false,
  });

  final MatrixPageData data;
  final DrawFormController controller;
  final bool busy;
  final DrawBlocker? blocker;
  final VoidCallback onDraw;
  final VoidCallback onOpenConfiguration;
  final void Function(BlockerFix fix) onFix;
  final VoidCallback onReload;

  /// The server's message when it rejected the draw's settings.
  final String? rejection;
  final bool networkFailure;
  final bool conflict;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final options = data.options;
    final seeded = options?.drawMode == DrawMode.seededManOnMan;
    final protection = options?.teamProtection ?? false;
    final minimum = protection ? data.largestTeam : 0;
    final check = DrawFormCheck.evaluate(
      roundsText: controller.rounds.text,
      groupsText: controller.groups.text,
      pilots: data.scoringPilots,
      minimumGroups: minimum,
      submitted: controller.submitted,
    );
    final groupsError = rejection != null
        ? 'Server: $rejection'
        : check.groupsError;
    final problems = [
      if (check.roundsError != null)
        (
          '${seeded ? 'Preliminary seeded rounds' : 'Number of rounds'}: '
              '${check.roundsError}',
          controller.rounds,
        ),
      if (groupsError != null)
        (
          'Groups per round: ${groupsError.replaceFirst('Server: ', '')}',
          controller.groups,
        ),
    ];
    final locked = blocker != null || busy;
    final configuredRounds = controller.configuredRounds;

    String note(int? configured, String source, String text) =>
        configured == null
        ? 'Contest configuration has no value. Enter one here, or set it in '
              'Configuration.'
        : 'From $source: $text';
    String edited(int? configured) =>
        'Differs from the suggested value ($configured). Changing it here '
        'doesn’t change the contest configuration.';

    final roundsNote =
        DrawFormController.isEdited(controller.rounds.text, configuredRounds)
        ? edited(configuredRounds)
        : note(
            configuredRounds,
            controller.roundsSource,
            seeded
                ? '$configuredRounds preliminary seeded rounds'
                : '$configuredRounds rounds',
          );
    final groupsNote = controller.groupsEdited
        ? edited(controller.configuredGroups)
        : note(
            controller.configuredGroups,
            controller.groupsSource,
            '${controller.configuredGroups} groups per round',
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        if (networkFailure)
          MatrixBanner(
            kind: MatrixBannerKind.error,
            icon: Icons.cloud_off,
            title: 'Couldn’t reach the server',
            body:
                'The matrix wasn’t drawn and the page hasn’t changed. Your '
                'values are kept.',
            actions: [
              PageBannerAction(
                'Try again',
                onDraw,
                emphasis: PageBannerEmphasis.filled,
                key: const ValueKey('try-again'),
              ),
            ],
          ),
        if (conflict)
          MatrixBanner(
            kind: MatrixBannerKind.warning,
            icon: Icons.sync_problem,
            title: 'This contest changed on the server',
            body:
                'A matrix has already been drawn for this contest, or the '
                'contest can no longer be drawn. Reload to see the current '
                'state. Your values stay until you reload.',
            actions: [
              PageBannerAction(
                'Reload',
                onReload,
                emphasis: PageBannerEmphasis.filled,
                key: const ValueKey('reload'),
              ),
            ],
          ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: const Icon(Icons.grid_view),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No matrix drawn yet',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      'No flight matrix has been drawn for this contest. For '
                      'now, drawing is a one-time action. Redrawing comes in '
                      'a later release.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20,
              children: [
                Text(
                  'Draw the first matrix',
                  style: theme.textTheme.titleMedium,
                ),
                if (problems.isNotEmpty &&
                    (rejection != null || controller.submitted))
                  MatrixBanner(
                    kind: MatrixBannerKind.error,
                    icon: Icons.error_outline,
                    title: rejection != null
                        ? 'The server rejected the draw'
                        : 'Fix ${problems.length} field'
                              '${problems.length == 1 ? '' : 's'} before drawing',
                    body:
                        '${problems.map((p) => p.$1).join('\n')}\n'
                        'Your values are kept. Nothing was drawn.',
                  ),
                ExcludeFocus(
                  excluding: locked,
                  child: IgnorePointer(
                    ignoring: locked,
                    child: Opacity(
                      opacity: locked ? .55 : 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 20,
                        children: [
                          Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            children: [
                              SizedBox(
                                width: 330,
                                child: DrawNumberField(
                                  fieldKey: const ValueKey('draw-rounds'),
                                  label: seeded
                                      ? 'Preliminary seeded rounds'
                                      : 'Number of rounds',
                                  controller: controller.rounds,
                                  note: roundsNote,
                                  error: check.roundsError,
                                  edited: controller.roundsEdited,
                                  resetLabel: 'Reset to $configuredRounds',
                                  onReset: () => controller.rounds.text =
                                      '$configuredRounds',
                                  onOpenConfiguration: onOpenConfiguration,
                                ),
                              ),
                              SizedBox(
                                width: 330,
                                child: DrawNumberField(
                                  fieldKey: const ValueKey('draw-groups'),
                                  label: 'Groups per round',
                                  controller: controller.groups,
                                  note: groupsNote,
                                  error: groupsError,
                                  warning: check.groupsWarning,
                                  edited: controller.groupsEdited,
                                  resetLabel:
                                      'Reset to ${controller.configuredGroups}',
                                  onReset: () => controller.groups.text =
                                      '${controller.configuredGroups}',
                                  onOpenConfiguration: onOpenConfiguration,
                                ),
                              ),
                            ],
                          ),
                          GroupSizePreview(
                            check: check,
                            pilots: data.scoringPilots,
                            minimumGroups: minimum,
                            largestTeam: data.largestTeamName,
                            seededRounds: seeded
                                ? (configuredRounds ??
                                      options?.preliminaryRounds)
                                : null,
                          ),
                          DrawConfigRows(
                            data: data,
                            onOpenConfiguration: onOpenConfiguration,
                          ),
                          DrawAdvancedSection(controller: controller),
                        ],
                      ),
                    ),
                  ),
                ),
                Divider(color: scheme.outlineVariant),
                DrawActionRow(
                  busy: busy,
                  blocker: blocker,
                  reloadReason: conflict
                      ? 'Reload the contest before drawing.'
                      : null,
                  onDraw: onDraw,
                  onFix: onFix,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
