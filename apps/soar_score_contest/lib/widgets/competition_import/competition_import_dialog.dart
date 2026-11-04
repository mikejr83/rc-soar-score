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
    final contests = _c.listed;
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
          for (final c in contests) _CompetitionRow(controller: _c, draft: c),
        ],
      ),
    );
  }

  Widget _confirm(BuildContext context, AppLocalizations l10n) {
    final plan = _c.plan;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.competitionImportConfirmIntro),
        const SizedBox(height: 12),
        for (final c in _c.chosenCompetitions)
          Text(
            '• ${c.name ?? ''}',
            key: ValueKey('competition-import-sum-${c.sourceCompNo}'),
          ),
        const SizedBox(height: 12),
        if (plan.contests > 0) ...[
          Text(
            l10n.competitionImportSummaryContests(plan.contests),
            key: const ValueKey('competition-import-summary-contests'),
          ),
          Text(
            l10n.competitionImportSummaryPilots(
              plan.newPilots,
              plan.updatedPilots,
            ),
            key: const ValueKey('competition-import-summary-pilots'),
          ),
          const SizedBox(height: 8),
          Text(l10n.competitionImportNotImported),
        ],
        if (_c.drawsToAdd > 0) ...[
          for (final offer in _c.chosenOffers)
            Text(
              '• ${_nameOf(offer.draft.sourceCompNo)}',
              key: ValueKey(
                'competition-import-sum-draw-${offer.draft.sourceCompNo}',
              ),
            ),
          const SizedBox(height: 8),
          Text(
            l10n.competitionImportSummaryDraws(_c.drawsToAdd),
            key: const ValueKey('competition-import-summary-draws'),
          ),
          const SizedBox(height: 8),
          Text(l10n.competitionImportDrawNotImported),
        ],
      ],
    );
  }

  String _nameOf(int compNo) {
    for (final c in _c.draft?.contests ?? const <ContestImportDraft>[]) {
      if (c.sourceCompNo == compNo) return c.name ?? '';
    }
    return '';
  }

  Widget _done(BuildContext context, AppLocalizations l10n) => ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 460),
    child: ListView(
      shrinkWrap: true,
      key: const ValueKey('competition-import-result'),
      children: [
        for (final r in _c.results)
          _resultRow(context, l10n, r, _nameOf(r.sourceCompNo)),
        for (final r in _c.drawResults)
          _drawResultRow(l10n, r, _nameOf(r.sourceCompNo)),
      ],
    ),
  );

  Widget _drawResultRow(
    AppLocalizations l10n,
    DrawImportResult r,
    String name,
  ) {
    final key = ValueKey('competition-import-draw-result-${r.sourceCompNo}');
    switch (r) {
      case DrawImported():
        return ListTile(
          key: key,
          dense: true,
          leading: const Icon(Icons.check_circle_outline),
          title: Text(
            l10n.competitionImportResultDrawAdded(
              name,
              r.roundCount,
              r.assignmentCount,
            ),
          ),
          trailing: TextButton(
            key: ValueKey('competition-import-open-draw-${r.sourceCompNo}'),
            onPressed: () => _close(r.contestId),
            child: Text(l10n.competitionImportOpen),
          ),
        );
      case DrawImportFailed():
        return ListTile(
          key: key,
          dense: true,
          leading: Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(
            l10n.competitionImportResultDrawFailed(
              name,
              _drawReasonText(l10n, r.code),
            ),
          ),
        );
    }
  }

  Widget _resultRow(
    BuildContext context,
    AppLocalizations l10n,
    CompetitionImportResult r,
    String name,
  ) {
    final key = ValueKey('competition-import-result-${r.sourceCompNo}');
    switch (r) {
      case CompetitionImported():
        return ListTile(
          key: key,
          dense: true,
          leading: const Icon(Icons.check_circle_outline),
          title: Text(l10n.competitionImportResultImported(name)),
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
      case CompetitionAlreadyImported():
        final date = MaterialLocalizations.of(context)
            .formatMediumDate(r.importedAt.toLocal());
        final id = r.contestId;
        return ListTile(
          key: key,
          dense: true,
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.competitionImportResultAlready(name, date)),
          trailing: id == null
              ? null
              : TextButton(
                  key: ValueKey('competition-import-open-${r.sourceCompNo}'),
                  onPressed: () => _close(id),
                  child: Text(l10n.competitionImportOpen),
                ),
        );
      case CompetitionImportFailed():
        return ListTile(
          key: key,
          dense: true,
          leading: Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(
            l10n.competitionImportResultFailed(
              name,
              _failureText(l10n, r.code),
            ),
          ),
        );
    }
  }

  Widget _failed(BuildContext context, AppLocalizations l10n) {
    final text = _c.changedDuringReview
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
            onPressed: _c.chosenTotal == 0 ? null : _c.continueFromCompetitions,
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
            onPressed: _c.apply,
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

String _failureText(AppLocalizations l10n, String code) => switch (code) {
  CompetitionImportFailure.noAccount => l10n.competitionImportFailNoAccount,
  CompetitionImportFailure.notImportable =>
    l10n.competitionImportFailNotImportable,
  CompetitionImportFailure.profileUnavailable =>
    l10n.competitionImportFailProfileUnavailable,
  CompetitionImportFailure.configInvalid =>
    l10n.competitionImportFailConfigInvalid,
  CompetitionImportFailure.profileMissing =>
    l10n.competitionImportFailProfileMissing,
  _ => l10n.competitionImportFailOther,
};

String _reasonText(AppLocalizations l10n, String? code) => switch (code) {
  ContestImportReason.classNotSupportedYet =>
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
  _ => l10n.competitionImportReasonOther,
};

/// Why the draw of a competition cannot be added, for a refusal or a failure.
String _drawReasonText(AppLocalizations l10n, String? code) => switch (code) {
  DrawImportReason.fingerprintChanged =>
    l10n.competitionImportDrawReasonFingerprint,
  DrawImportReason.alreadyDrawn => l10n.competitionImportDrawReasonDrawn,
  DrawImportReason.hasAcceptedScores => l10n.competitionImportDrawReasonScores,
  DrawImportReason.noDraw => l10n.competitionImportDrawReasonNoDraw,
  DrawImportReason.pilotWithoutParticipation ||
  DrawImportFailure.participationMissing =>
    l10n.competitionImportDrawReasonPilot,
  DrawImportReason.creditMoved => l10n.competitionImportDrawReasonMoved,
  DrawImportReason.taskRangesOverlap ||
  DrawImportReason.taskRangesGapped ||
  DrawImportReason.duplicateFlight ||
  DrawImportReason.reflightWithoutOriginal ||
  DrawImportReason.keyMissing => l10n.competitionImportDrawReasonRounds,
  DrawImportFailure.contestLocked => l10n.competitionImportDrawFailLocked,
  DrawImportFailure.noAccount => l10n.competitionImportFailNoAccount,
  DrawImportFailure.failed => l10n.competitionImportFailOther,
  _ => l10n.competitionImportDrawReasonOther,
};

/// One competition of the file: a checkbox when it can be imported, else the
/// reason it cannot.
class _CompetitionRow extends StatelessWidget {
  const _CompetitionRow({required this.controller, required this.draft});

  final CompetitionImportController controller;
  final ContestImportDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final no = draft.sourceCompNo;
    final name = draft.name ?? draft.sourceClass;
    final importable = draft.isImportable;
    final date = draft.startDate == null
        ? ''
        : MaterialLocalizations.of(context).formatMediumDate(draft.startDate!);
    final warnings = {for (final w in draft.warnings) w.code};
    final other = draft.warnings
        .where(
          (w) =>
              w.code != ContestImportWarning.teamNamesGenerated &&
              w.code != ContestImportWarning.retiredKeptActive,
        )
        .length;
    final notes = [
      if (!importable) _reasonText(l10n, draft.reason),
      if (importable)
        l10n.competitionImportRowDetails(
          date,
          draft.sourceClass,
          draft.participants.length,
        ),
      if (warnings.contains(ContestImportWarning.teamNamesGenerated))
        l10n.competitionImportWarningTeamNames,
      if (warnings.contains(ContestImportWarning.retiredKeptActive))
        l10n.competitionImportWarningRetired,
      if (other > 0) l10n.competitionImportWarningOther(other),
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
    final offer = controller.offers[no];
    if (offer == null) return tile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tile,
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: _DrawOfferTile(controller: controller, offer: offer),
        ),
      ],
    );
  }
}

/// The draw a competition imported before can still receive: a checkbox with
/// the counts and notes of the dry run, or the reason it cannot be added.
class _DrawOfferTile extends StatelessWidget {
  const _DrawOfferTile({required this.controller, required this.offer});

  final CompetitionImportController controller;
  final DrawOffer offer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = offer.draft;
    final no = draft.sourceCompNo;
    if (!offer.canAdd) {
      return ListTile(
        key: ValueKey('competition-import-draw-refused-$no'),
        dense: true,
        leading: const Icon(Icons.info_outline),
        title: Text(l10n.competitionImportDrawTitle),
        subtitle: Text(_drawReasonText(l10n, draft.reason)),
      );
    }
    int count(Set<String> codes) =>
        draft.warnings.where((w) => codes.contains(w.code)).length;
    final groups = count({DrawImportWarning.groupsPerRoundDiffers});
    final sizes = count({DrawImportWarning.groupSizesDiffer});
    final lanes = count({DrawImportWarning.laneBeyondLaneCount});
    final other = count({
      DrawImportWarning.emptyGroup,
      DrawImportWarning.seqNoDuplicate,
      DrawImportWarning.seqNoMissing,
    });
    final notes = [
      l10n.competitionImportDrawIntro,
      l10n.competitionImportDrawDetails(
        draft.roundCount,
        draft.maxGroupsPerRound,
        draft.pilots.length,
      ),
      draft.laneCount > 0
          ? l10n.competitionImportDrawLanes(draft.laneCount)
          : l10n.competitionImportDrawNoLanes,
      if (draft.probablyUnflownRounds.length == draft.roundCount)
        l10n.competitionImportDrawNoScores
      else if (draft.probablyUnflownRounds.isNotEmpty)
        l10n.competitionImportDrawUnflown(draft.probablyUnflownRounds.length),
      l10n.competitionImportDrawNoteHistory,
      if (groups > 0) l10n.competitionImportDrawWarningGroups(groups),
      if (sizes > 0) l10n.competitionImportDrawWarningSizes(sizes),
      if (lanes > 0) l10n.competitionImportDrawWarningLanes(lanes),
      if (other > 0) l10n.competitionImportDrawWarningOther(other),
    ];
    return CheckboxListTile(
      key: ValueKey('competition-import-draw-$no'),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      value: controller.chosenDraws.contains(no),
      onChanged: (_) => controller.toggleDraw(no),
      title: Text(l10n.competitionImportDrawTitle),
      subtitle: Text(notes.join('\n')),
    );
  }
}
