import 'package:material_ui/material_ui.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/configuration/draw_readiness.dart';
import '../../services/matrix/draw_form_check.dart';
import '../../services/matrix/draw_form_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../services/matrix/matrix_page_data.dart';
import '../../services/matrix/matrix_rounds_plan.dart';
import 'draw_action_row.dart';
import 'draw_advanced_section.dart';
import 'draw_config_rows.dart';
import 'draw_number_field.dart';
import 'group_size_preview.dart';
import '../page_states/page_banner.dart';
import 'matrix_banner.dart';
import 'round_span.dart';

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
    this.progress,
    this.cancelling = false,
    this.cancelFailed = false,
    this.onCancel,
    this.rejection,
    this.networkFailure = false,
    this.conflict = false,
    this.intent,
    this.plan,
    this.onBack,
  });

  final MatrixPageData data;
  final DrawFormController controller;
  final bool busy;
  final DrawBlocker? blocker;
  final VoidCallback onDraw;
  final VoidCallback onOpenConfiguration;
  final void Function(BlockerFix fix) onFix;
  final VoidCallback onReload;

  /// The running draw's progress, and the way to cancel it (see
  /// [DrawActionRow]).
  final DrawStatusDto? progress;
  final bool cancelling;
  final bool cancelFailed;
  final VoidCallback? onCancel;

  /// The server's message when it rejected the draw's settings.
  final String? rejection;
  final bool networkFailure;
  final bool conflict;

  /// Set when the form adds rounds to, or redraws rounds of, a drawn matrix
  /// ([plan] describes it); `null` for the first draw.
  final MatrixIntent? intent;
  final MatrixRoundsPlan? plan;

  /// Leaves the form for the matrix (add rounds and redraw only).
  final VoidCallback? onBack;

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
    final l10n = AppLocalizations.of(context);
    final plan = this.plan;
    final adding = intent == MatrixIntent.addRounds;
    final rounding = plan != null;
    final firstRound = plan == null ? 1 : plan.firstRound(intent!);
    final count = check.rounds ?? 0;
    final preliminary = seeded ? options?.preliminaryRounds : null;
    // Seeded rounds come from the standings, so they are drawn one at a time.
    final roundsError =
        check.roundsError ??
        (rounding &&
                preliminary != null &&
                firstRound > preliminary &&
                count > 1
            ? l10n.matrixSeededOneRound
            : null);
    final serverPrefix = l10n.matrixServerPrefix;
    final groupsError = rejection != null
        ? '$serverPrefix$rejection'
        : check.groupsError;
    final problems = [
      if (roundsError != null)
        (
          '${seeded ? l10n.matrixSeededRoundsLabel : l10n.matrixRoundsLabel}: '
              '$roundsError',
          controller.rounds,
        ),
      if (groupsError != null)
        (
          l10n.matrixGroupsErrorLabel(
            groupsError.replaceFirst(serverPrefix, ''),
          ),
          controller.groups,
        ),
    ];
    final locked = blocker != null || busy;
    final configuredRounds = controller.configuredRounds;
    final configuredGroups = controller.configuredGroups;

    String note(int? configured, String source, String text) =>
        configured == null
        ? l10n.matrixNoteNoValue
        : l10n.matrixNoteFrom(source, text);
    String edited(int? configured) => configured == null
        ? l10n.matrixNoteNoValue
        : l10n.matrixNoteEdited(configured);

    final firstRoundsNote =
        DrawFormController.isEdited(controller.rounds.text, configuredRounds)
        ? edited(configuredRounds)
        : note(
            configuredRounds,
            controller.roundsSource,
            configuredRounds == null
                ? ''
                : seeded
                ? l10n.matrixSeededRoundsText(configuredRounds)
                : l10n.matrixRoundsText(configuredRounds),
          );
    final firstGroupsNote = controller.groupsEdited
        ? edited(configuredGroups)
        : note(
            configuredGroups,
            controller.groupsSource,
            configuredGroups == null
                ? ''
                : l10n.matrixGroupsText(configuredGroups),
          );
    final lastNew = firstRound + count - 1;
    final roundsNote = plan == null
        ? firstRoundsNote
        : count < 1
        ? ''
        : adding
        ? l10n.matrixAddRoundsNote(roundSpan(l10n, firstRound, lastNew))
        : count < plan.unscoredRounds
        ? l10n.matrixRedrawRoundsRemoved(
            roundSpan(l10n, firstRound, lastNew),
            roundSpan(l10n, lastNew + 1, plan.lastRound),
          )
        : l10n.matrixRedrawRoundsNote(roundSpan(l10n, firstRound, lastNew));
    final groupsNote = plan == null
        ? firstGroupsNote
        : l10n.matrixGroupsFromRound(
            adding ? plan.lastRound : plan.firstUnscored,
          );
    final roundsLabel = rounding
        ? (adding ? l10n.matrixRoundsToAdd : l10n.matrixRoundsToDraw)
        : seeded
        ? l10n.matrixSeededRoundsLabel
        : l10n.matrixRoundsLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        if (onBack != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('back-to-matrix'),
              onPressed: busy ? null : onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(l10n.matrixBackToMatrix),
            ),
          ),
        if (networkFailure)
          MatrixBanner(
            kind: MatrixBannerKind.error,
            icon: Icons.cloud_off,
            title: l10n.matrixNetworkTitle,
            body: rounding
                ? l10n.matrixRoundsNetworkFailure
                : l10n.matrixNetworkFirstBody,
            actions: [
              PageBannerAction(
                l10n.matrixTryAgain,
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
            title: l10n.matrixConflictTitle,
            body: rounding
                ? l10n.matrixRoundsConflict
                : l10n.matrixConflictFirstBody,
            actions: [
              PageBannerAction(
                l10n.matrixReload,
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
                      plan == null
                          ? l10n.matrixNoMatrixTitle
                          : adding
                          ? l10n.matrixAddTitle
                          : l10n.matrixRedrawTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      plan == null
                          ? l10n.matrixNoMatrixIntro
                          : adding
                          ? l10n.matrixAddIntro(plan.lastRound)
                          : l10n.matrixRedrawIntro(
                              roundSpan(
                                l10n,
                                plan.firstUnscored,
                                plan.lastRound,
                              ),
                            ),
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
                if (plan == null)
                  Text(
                    l10n.matrixDrawFirstTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                if (problems.isNotEmpty &&
                    (rejection != null || controller.submitted))
                  MatrixBanner(
                    kind: MatrixBannerKind.error,
                    icon: Icons.error_outline,
                    title: rejection != null
                        ? (rounding
                              ? l10n.matrixRoundsRejected
                              : l10n.matrixServerRejected)
                        : l10n.matrixFixFields(
                            problems.length,
                            problems.length == 1 ? '' : 's',
                          ),
                    body:
                        '${problems.map((p) => p.$1).join('\n')}\n'
                        '${l10n.matrixErrorsKept}',
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
                                  label: roundsLabel,
                                  controller: controller.rounds,
                                  note: roundsNote,
                                  error: roundsError,
                                  edited: !rounding && controller.roundsEdited,
                                  resetLabel: l10n.matrixResetTo(
                                    '$configuredRounds',
                                  ),
                                  onReset: () => controller.rounds.text =
                                      '$configuredRounds',
                                  onOpenConfiguration: onOpenConfiguration,
                                ),
                              ),
                              SizedBox(
                                width: 330,
                                child: DrawNumberField(
                                  fieldKey: const ValueKey('draw-groups'),
                                  label: l10n.matrixGroupsLabel,
                                  controller: controller.groups,
                                  note: groupsNote,
                                  error: groupsError,
                                  warning: check.groupsWarning,
                                  edited: !rounding && controller.groupsEdited,
                                  resetLabel: l10n.matrixResetTo(
                                    '${controller.configuredGroups}',
                                  ),
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
                          if (rounding)
                            TextField(
                              key: const ValueKey('draw-reason'),
                              controller: controller.reason,
                              decoration: InputDecoration(
                                labelText: l10n.matrixReasonLabel,
                                hintText: l10n.matrixReasonHint,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          DrawAdvancedSection(controller: controller),
                        ],
                      ),
                    ),
                  ),
                ),
                Divider(color: scheme.outlineVariant),
                DrawActionRow(
                  intent: intent,
                  busy: busy,
                  blocker: blocker,
                  reloadReason: conflict ? l10n.matrixActionReload : null,
                  onDraw: onDraw,
                  onFix: onFix,
                  progress: progress,
                  cancelling: cancelling,
                  cancelFailed: cancelFailed,
                  onCancel: onCancel,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
