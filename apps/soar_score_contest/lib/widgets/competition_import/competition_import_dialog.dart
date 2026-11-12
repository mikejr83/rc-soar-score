import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../api_client_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/competition_import/competition_import.dart';
import '../api_error_text.dart';
import '../pilot_import/pilot_import_dialog.dart';

/// What the competition import did, for the page that started it.
class CompetitionImportOutcome {
  const CompetitionImportOutcome({required this.imported, this.open});

  /// The contests that were written.
  final List<Id> imported;

  /// The contest the director asked to open, if any.
  final Id? open;
}

/// Imports competitions of a GliderScore database as contests: choose the
/// file, choose competitions, review their pilots, confirm, then see what
/// happened to each.
///
/// Returns null when nothing was written. Does nothing when the build has no
/// competition import.
Future<CompetitionImportOutcome?> importCompetitions(
  BuildContext context,
) async {
  final store = CompetitionImportStore.current;
  final client = apiClientOf(context);
  if (store == null || client == null) return null;
  final controller = CompetitionImportController(
    store: store,
    readFile: (path) => CompetitionImportController.read(client, path),
  );
  final outcome = await showDialog<CompetitionImportOutcome>(
    context: context,
    barrierDismissible: false,
    builder: (_) => CompetitionImportDialog(controller: controller),
  );
  controller.dispose();
  return outcome;
}

/// The competition import dialog; [controller] holds the state.
class CompetitionImportDialog extends StatefulWidget {
  const CompetitionImportDialog({super.key, required this.controller});

  final CompetitionImportController controller;

  @override
  State<CompetitionImportDialog> createState() =>
      _CompetitionImportDialogState();
}

class _CompetitionImportDialogState extends State<CompetitionImportDialog> {
  CompetitionImportController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chosen = await _c.chooseAndRead();
      if (!chosen && mounted) Navigator.of(context).pop();
    });
  }

  void _close([Id? open]) => Navigator.of(context).pop(
    _c.anyImported
        ? CompetitionImportOutcome(imported: _c.importedContestIds, open: open)
        : null,
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        key: const ValueKey('competition-import-dialog'),
        title: Text(l10n.competitionImportTitle),
        content: SizedBox(width: 640, child: _content(context, l10n)),
        actions: _actions(context, l10n),
      );
    },
  );

  Widget _content(BuildContext context, AppLocalizations l10n) =>
      switch (_c.step) {
        CompetitionImportStep.idle => _busy(l10n.competitionImportChoosing),
        CompetitionImportStep.reading => _busy(
          l10n.competitionImportReading(_c.fileName ?? ''),
        ),
        CompetitionImportStep.applying => _busy(l10n.competitionImportSaving),
        CompetitionImportStep.competitions => _competitions(context, l10n),
        CompetitionImportStep.pilots => PilotImportReviewList(
          controller: _c.pilots,
        ),
        CompetitionImportStep.confirm => _confirm(context, l10n),
        CompetitionImportStep.done => _done(context, l10n),
        CompetitionImportStep.failed => _failed(context, l10n),
      };

  Widget _busy(String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Row(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(label)),
      ],
    ),
  );

  Widget _competitions(BuildContext context, AppLocalizations l10n) {
    final plans = _c.listed;
    final hasImportable = _c.importable.isNotEmpty;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 460),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(l10n.competitionImportIntro),
          if (!hasImportable)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                l10n.competitionImportNothingImportable,
                key: const ValueKey('competition-import-empty'),
              ),
            ),
          if (hasImportable)
            Row(
              children: [
                TextButton(
                  key: const ValueKey('competition-import-select-all'),
                  onPressed: () => _c.setAll(true),
                  child: Text(l10n.competitionImportSelectAll),
                ),
                TextButton(
                  key: const ValueKey('competition-import-select-none'),
                  onPressed: () => _c.setAll(false),
                  child: Text(l10n.competitionImportSelectNone),
                ),
              ],
            ),
          for (final plan in plans) _CompetitionRow(controller: _c, plan: plan),
        ],
      ),
    );
  }

  /// The summary lists the contests by name when there are fewer than this.
  static const _namedContestsLimit = 10;

  Widget _confirm(BuildContext context, AppLocalizations l10n) {
    final summary = _c.summary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.competitionImportConfirmIntro),
        const SizedBox(height: 12),
        // A long list would overflow the dialog: name the contests only when
        // there are few, otherwise the counts below say it.
        if (_c.chosenPlans.length < _namedContestsLimit) ...[
          for (final plan in _c.chosenPlans)
            Text(
              '• ${plan.contest.name ?? ''}',
              key: ValueKey('competition-import-sum-${plan.sourceCompNo}'),
            ),
          const SizedBox(height: 12),
        ],
        if (summary.created > 0)
          Text(
            l10n.competitionImportSummaryContests(summary.created),
            key: const ValueKey('competition-import-summary-contests'),
          ),
        if (summary.replaced > 0)
          Text(
            l10n.competitionImportSummaryReplaced(summary.replaced),
            key: const ValueKey('competition-import-summary-replaced'),
          ),
        if (summary.unchanged > 0)
          Text(
            l10n.competitionImportSummaryUnchanged(summary.unchanged),
            key: const ValueKey('competition-import-summary-unchanged'),
          ),
        Text(
          l10n.competitionImportSummaryPilots(
            summary.newPilots,
            summary.updatedPilots,
          ),
          key: const ValueKey('competition-import-summary-pilots'),
        ),
        Text(
          l10n.competitionImportSummaryFlights(summary.flights),
          key: const ValueKey('competition-import-summary-flights'),
        ),
        if (summary.completed > 0)
          Text(
            l10n.competitionImportSummaryCompleted(summary.completed),
            key: const ValueKey('competition-import-summary-completed'),
          ),
        const SizedBox(height: 8),
        Text(l10n.competitionImportSummaryCheck),
        if (_c.needsReplaceConfirmation)
          CheckboxListTile(
            key: const ValueKey('competition-import-confirm-replace'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            value: _c.replaceConfirmed,
            onChanged: (v) => _c.setReplaceConfirmed(v ?? false),
            title: Text(l10n.competitionImportConfirmReplace),
          ),
      ],
    );
  }

  String _nameOf(int compNo) => _c.planOf(compNo)?.contest.name ?? '';

  Widget _done(BuildContext context, AppLocalizations l10n) => ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 460),
    child: ListView(
      shrinkWrap: true,
      key: const ValueKey('competition-import-result'),
      children: [
        for (final r in _c.results)
          _resultRow(context, l10n, r, _nameOf(r.sourceCompNo)),
      ],
    ),
  );

  Widget _resultRow(
    BuildContext context,
    AppLocalizations l10n,
    RestoreImportResult r,
    String name,
  ) {
    final key = ValueKey('competition-import-result-${r.sourceCompNo}');
    final error = Theme.of(context).colorScheme.error;
    switch (r) {
      case CompetitionRestored():
        return ListTile(
          key: key,
          dense: true,
          leading: const Icon(Icons.check_circle_outline),
          title: Text(
            r.updated
                ? l10n.competitionImportResultReplaced(name, r.flightCount)
                : l10n.competitionImportResultRestored(name, r.flightCount),
          ),
          subtitle: r.skippedParticipants.isEmpty
              ? null
              : Text(
                  l10n.competitionImportResultSkippedPilots(
                    r.skippedParticipants.length,
                  ),
                ),
          trailing: TextButton(
            key: ValueKey('competition-import-open-${r.sourceCompNo}'),
            onPressed: () => _close(r.contestId),
            child: Text(l10n.competitionImportOpen),
          ),
        );
      case CompetitionUnchanged():
        return ListTile(
          key: key,
          dense: true,
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.competitionImportResultUnchanged(name)),
          trailing: TextButton(
            key: ValueKey('competition-import-open-${r.sourceCompNo}'),
            onPressed: () => _close(r.contestId),
            child: Text(l10n.competitionImportOpen),
          ),
        );
      case CompetitionRefused():
        return ListTile(
          key: key,
          dense: true,
          leading: Icon(Icons.error_outline, color: error),
          title: Text(
            l10n.competitionImportResultRefused(
              name,
              _refusalText(l10n, r.code),
            ),
          ),
        );
      case CompetitionRestoreFailed():
        return ListTile(
          key: key,
          dense: true,
          leading: Icon(Icons.error_outline, color: error),
          title: Text(
            l10n.competitionImportResultRefused(name, _failureText(l10n, r)),
          ),
        );
    }
  }

  Widget _failed(BuildContext context, AppLocalizations l10n) {
    final text = _c.pilots.linkReviewPending
        ? l10n.pilotImportLinkReviewPending
        : _c.changedDuringReview
        ? l10n.pilotImportChangedDuringReview
        : l10n.competitionImportFailed(apiErrorText(_c.error!));
    return Text(
      text,
      key: const ValueKey('competition-import-error'),
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }

  List<Widget> _actions(BuildContext context, AppLocalizations l10n) {
    switch (_c.step) {
      case CompetitionImportStep.idle:
        return const [];
      case CompetitionImportStep.reading:
        return [
          TextButton(
            key: const ValueKey('competition-import-cancel-reading'),
            onPressed: () {
              _c.cancelReading();
              Navigator.of(context).pop();
            },
            child: Text(l10n.competitionImportCancelReading),
          ),
        ];
      case CompetitionImportStep.applying:
        return const [];
      case CompetitionImportStep.competitions:
        return [
          Text(
            l10n.competitionImportChosenCount(_c.chosenTotal),
            key: const ValueKey('competition-import-chosen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            key: const ValueKey('competition-import-continue'),
            onPressed: _c.chosenTotal == 0 ? null : _c.continueToPilots,
            child: Text(l10n.competitionImportContinue),
          ),
        ];
      case CompetitionImportStep.pilots:
        return [
          TextButton(
            key: const ValueKey('competition-import-back'),
            onPressed: _c.backToCompetitions,
            child: Text(l10n.competitionImportBack),
          ),
          FilledButton(
            key: const ValueKey('competition-import-continue'),
            onPressed: _c.continueToConfirm,
            child: Text(l10n.competitionImportContinue),
          ),
        ];
      case CompetitionImportStep.confirm:
        return [
          TextButton(
            key: const ValueKey('competition-import-back'),
            onPressed: _c.backToPilots,
            child: Text(l10n.competitionImportBack),
          ),
          FilledButton(
            key: const ValueKey('competition-import-confirm'),
            onPressed: _c.needsReplaceConfirmation && !_c.replaceConfirmed
                ? null
                : _c.apply,
            child: Text(l10n.competitionImportConfirm),
          ),
        ];
      case CompetitionImportStep.done:
        return [
          FilledButton(
            key: const ValueKey('competition-import-done'),
            onPressed: _close,
            child: Text(l10n.competitionImportDoneButton),
          ),
        ];
      case CompetitionImportStep.failed:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancelButton),
          ),
          if (_c.changedDuringReview || _c.canReviewAgain)
            FilledButton(
              key: const ValueKey('competition-import-review-again'),
              onPressed: _c.reviewAgain,
              child: Text(l10n.pilotImportReviewAgain),
            ),
        ];
    }
  }
}

/// Why a restore failed and kept nothing.
String _failureText(AppLocalizations l10n, CompetitionRestoreFailed r) =>
    switch (r.code) {
      RestoreFailure.noAccount => l10n.competitionImportFailNoAccount,
      RestoreFailure.notImportable => l10n.competitionImportFailNotImportable,
      RestoreFailure.profileUnavailable =>
        l10n.competitionImportFailProfileUnavailable,
      RestoreFailure.configInvalid => l10n.competitionImportFailConfigInvalid,
      RestoreFailure.profileMissing => l10n.competitionImportFailProfileMissing,
      RestoreFailure.drawParticipantMissing =>
        l10n.competitionImportFailDrawParticipant(r.detail ?? ''),
      RestoreFailure.comparisonFailed => l10n.competitionImportFailComparison(
        r.mismatchCount,
        [
          for (final m in r.mismatches)
            l10n.competitionImportMismatchFlight(
              m.roundNo,
              m.groupNo,
              m.sourcePilotNo,
            ),
        ].join('; '),
      ),
      _ => l10n.competitionImportFailOther,
    };

String _refusalText(AppLocalizations l10n, String code) => switch (code) {
  RestoreRefusal.contestSynced => l10n.competitionImportRefuseSynced,
  RestoreRefusal.resultsPublished => l10n.competitionImportRefusePublished,
  RestoreRefusal.needsConfirmation => l10n.competitionImportRefuseConfirm,
  RestoreRefusal.notRestorable => l10n.competitionImportRefuseNotRestorable,
  _ => l10n.competitionImportFailOther,
};

/// Why a competition cannot be listed as importable.
String _reasonText(
  AppLocalizations l10n,
  String? code,
  String? detail,
) => switch (code) {
  ContestImportReason.classNotSupportedYet ||
  RestoreReason.classNotSupported ||
  DrawImportReason.classNotSupported =>
    l10n.competitionImportReasonClassNotSupportedYet,
  ContestImportReason.classOutOfScope =>
    l10n.competitionImportReasonClassOutOfScope,
  ContestImportReason.classUnknown => l10n.competitionImportReasonClassUnknown,
  ContestImportReason.configMissing =>
    l10n.competitionImportReasonConfigMissing,
  ContestImportReason.dateMissing => l10n.competitionImportReasonDateMissing,
  ContestImportReason.configInvalid =>
    l10n.competitionImportReasonConfigInvalid,
  ContestImportReason.noParticipants =>
    l10n.competitionImportReasonNoParticipants,
  DrawImportReason.scoresUnavailable => l10n.competitionImportReasonNoScores,
  DrawImportReason.creditMoved => l10n.competitionImportReasonMoved,
  RestoreReason.reflightNotWholeGroup => l10n.competitionImportReasonReflights,
  RestoreReason.flightNotRepresentable => l10n.competitionImportReasonFlights(
    detail ?? '',
  ),
  DrawImportReason.taskRangesOverlap ||
  DrawImportReason.taskRangesGapped ||
  DrawImportReason.duplicateFlight ||
  DrawImportReason.reflightWithoutOriginal ||
  DrawImportReason.pilotWithoutParticipation ||
  DrawImportReason.noDraw ||
  DrawImportReason.keyMissing => l10n.competitionImportReasonRounds,
  _ => l10n.competitionImportReasonOther,
};

/// One competition of the file: a checkbox when it can be imported, else the
/// reason it cannot; the Completed choice and the earlier import it replaces
/// when chosen.
class _CompetitionRow extends StatelessWidget {
  const _CompetitionRow({required this.controller, required this.plan});

  final CompetitionImportController controller;
  final RestorePlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final no = plan.sourceCompNo;
    final draft = plan.contest;
    final name = draft.name ?? draft.sourceClass;
    final refusal = controller.refusalOf(no);
    final importable = plan.isImportable && refusal == null;
    final material = MaterialLocalizations.of(context);
    final date = draft.startDate == null
        ? ''
        : material.formatMediumDate(draft.startDate!);
    int count(String code) => plan.warnings.where((w) => w.code == code).length;
    final teamNames = draft.warnings.any(
      (w) => w.code == ContestImportWarning.teamNamesGenerated,
    );
    final other = draft.warnings
        .where(
          (w) =>
              w.code != ContestImportWarning.teamNamesGenerated &&
              w.code != ContestImportWarning.retiredKeptActive &&
              w.code != ContestImportWarning.landingTableNotImported,
        )
        .length;
    final target = controller.targetOf(no);
    final replaced = controller.replacedBy(no);
    final notes = [
      if (!plan.isImportable)
        _reasonText(l10n, plan.reason, plan.reasonDetail)
      else ...[
        '${l10n.competitionImportRowDetails(date, draft.sourceClass, draft.participants.length)}'
            ' · ${l10n.competitionImportRowFlights(plan.flights.length)}',
        if (teamNames) l10n.competitionImportWarningTeamNames,
        if (count(RestoreWarning.retirementInferred) > 0)
          l10n.competitionImportWarningRetirement(
            count(RestoreWarning.retirementInferred),
          ),
        if (plan.reflights.isNotEmpty)
          l10n.competitionImportWarningReflights(plan.reflights.length),
        if (count(RestoreWarning.motorRestartKept) > 0)
          l10n.competitionImportWarningRestart(
            count(RestoreWarning.motorRestartKept),
          ),
        if (count(RestoreWarning.roundPartlyFlown) > 0)
          l10n.competitionImportWarningUnflown(
            count(RestoreWarning.roundPartlyFlown),
          ),
        if (count(RestoreWarning.allZeroFlight) > 0)
          l10n.competitionImportWarningZero(
            count(RestoreWarning.allZeroFlight),
          ),
        if (count(RestoreWarning.landingUnresolved) > 0)
          l10n.competitionImportWarningLanding(
            count(RestoreWarning.landingUnresolved),
          ),
        if (other > 0) l10n.competitionImportWarningOther(other),
        ?_targetNote(l10n, target, replaced, refusal),
      ],
    ];
    final tile = CheckboxListTile(
      key: ValueKey('competition-import-row-$no'),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      enabled: importable,
      value: controller.chosen.contains(no),
      onChanged: importable ? (_) => controller.toggle(no) : null,
      title: Text(name),
      subtitle: Text(notes.join('\n')),
    );
    final numberMatch = target?.kind == RestoreTargetKind.numberMatch;
    final chosen = controller.chosen.contains(no);
    final showSame = plan.isImportable && numberMatch;
    if (!showSame && !(chosen && plan.hasScoredFlights)) return tile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tile,
        if (showSame)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: SwitchListTile(
              key: ValueKey('competition-import-same-$no'),
              dense: true,
              value: controller.isSameAs(no),
              onChanged: (v) => controller.setSameAs(no, v),
              title: Text(
                l10n.competitionImportTargetSame(target!.contestName ?? ''),
              ),
            ),
          ),
        if (chosen && plan.hasScoredFlights)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: CheckboxListTile(
              key: ValueKey('competition-import-completed-$no'),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              value: controller.completed(no),
              onChanged: (v) => controller.setCompleted(no, v ?? false),
              title: Text(l10n.competitionImportCompleted),
              subtitle: Text(l10n.competitionImportCompletedHint),
            ),
          ),
      ],
    );
  }

  String? _targetNote(
    AppLocalizations l10n,
    RestoreTarget? target,
    RestoreTarget? replaced,
    String? refusal,
  ) {
    if (target == null) return null;
    if (target.kind == RestoreTargetKind.numberMatch && replaced == null) {
      return l10n.competitionImportTargetNumberMatch(
        plan.identity.compNo,
        target.contestName ?? '',
        target.sourceDate ?? '',
      );
    }
    if (refusal == RestoreRefusal.resultsPublished) {
      return l10n.competitionImportTargetPublished;
    }
    if (refusal == RestoreRefusal.contestSynced) {
      return l10n.competitionImportTargetSynced;
    }
    final note =
        target.isUnchanged(
          plan.contentHash,
          controller.completed(plan.sourceCompNo),
        )
        ? l10n.competitionImportTargetUnchanged
        : l10n.competitionImportTargetReplaces(target.contestName ?? '');
    return target.changes.any && replaced != null
        ? '$note\n${l10n.competitionImportTargetChanges(target.changes.scoresEntered)}'
        : note;
  }
}
