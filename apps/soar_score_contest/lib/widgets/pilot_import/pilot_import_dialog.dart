import 'package:flutter/material.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../api_client_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/pilot_import/pilot_import.dart';
import '../api_error_text.dart';

/// Imports pilots from a GliderScore database into the director's
/// participants: choose the file, review what was found, then save.
///
/// Returns true when participants were added or updated, so the caller can
/// reload its list. Does nothing when the build has no pilot import.
Future<bool> importPilots(BuildContext context) async {
  final store = PilotImportStore.current;
  final client = apiClientOf(context);
  if (store == null || client == null) return false;
  final controller = PilotImportController(
    store: store,
    readFile: (path) {
      final read = GliderScoreFiles.current.read;
      return read != null
          ? read(client, path)
          : client.importGliderScore(path, tables: const ['Pilots']);
    },
  );
  final changed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PilotImportDialog(controller: controller),
  );
  controller.dispose();
  return changed ?? false;
}

/// The pilot import dialog; [controller] holds the state.
class PilotImportDialog extends StatefulWidget {
  const PilotImportDialog({super.key, required this.controller});

  final PilotImportController controller;

  @override
  State<PilotImportDialog> createState() => _PilotImportDialogState();
}

class _PilotImportDialogState extends State<PilotImportDialog> {
  PilotImportController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chosen = await _c.chooseAndRead();
      if (!chosen && mounted) Navigator.of(context).pop(false);
    });
  }

  bool get _saved {
    final outcome = _c.outcome;
    return outcome != null &&
        (outcome.added.isNotEmpty || outcome.updated.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        key: const ValueKey('pilot-import-dialog'),
        title: Text(l10n.pilotImportTitle),
        content: SizedBox(width: 640, child: _content(context, l10n)),
        actions: _actions(context, l10n),
      );
    },
  );

  Widget _content(BuildContext context, AppLocalizations l10n) =>
      switch (_c.step) {
        PilotImportStep.idle => _busy(l10n.pilotImportChoosing),
        PilotImportStep.reading => _busy(
          l10n.pilotImportReading(_c.fileName ?? ''),
        ),
        PilotImportStep.applying => _busy(l10n.pilotImportSaving),
        PilotImportStep.review => PilotImportReviewList(controller: _c),
        PilotImportStep.done => _done(l10n),
        PilotImportStep.failed => _failed(l10n),
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

  Widget _done(AppLocalizations l10n) {
    final o = _c.outcome!;
    return Text(
      l10n.pilotImportDone(
        o.added.length,
        o.updated.length,
        o.unchanged,
        o.skipped,
      ),
      key: const ValueKey('pilot-import-result'),
    );
  }

  Widget _failed(AppLocalizations l10n) {
    final error = _c.error!;
    final String text;
    if (_c.changedDuringReview) {
      text = l10n.pilotImportChangedDuringReview;
    } else if (error is ApiHttpError &&
        error.error?.code == 'import_unavailable') {
      text = l10n.pilotImportUnavailable;
    } else {
      text = l10n.pilotImportFailed(apiErrorText(error));
    }
    return Text(
      text,
      key: const ValueKey('pilot-import-error'),
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }

  List<Widget> _actions(BuildContext context, AppLocalizations l10n) {
    void close() => Navigator.of(context).pop(_saved);
    switch (_c.step) {
      case PilotImportStep.idle:
      case PilotImportStep.reading:
      case PilotImportStep.applying:
        return const [];
      case PilotImportStep.review:
        final plan = _c.plan;
        final any = plan.added + plan.updated + plan.unchanged > 0;
        return [
          Text(
            l10n.pilotImportPlan(
              plan.added,
              plan.updated,
              plan.unchanged,
              plan.skipped,
            ),
            key: const ValueKey('pilot-import-plan'),
          ),
          TextButton(onPressed: close, child: Text(l10n.cancelButton)),
          FilledButton(
            key: const ValueKey('pilot-import-confirm'),
            onPressed: any ? _c.apply : null,
            child: Text(l10n.pilotImportConfirm),
          ),
        ];
      case PilotImportStep.done:
        return [
          FilledButton(
            key: const ValueKey('pilot-import-done'),
            onPressed: close,
            child: Text(l10n.pilotImportDoneButton),
          ),
        ];
      case PilotImportStep.failed:
        return [
          TextButton(onPressed: close, child: Text(l10n.cancelButton)),
          if (_c.changedDuringReview)
            FilledButton(
              key: const ValueKey('pilot-import-review-again'),
              onPressed: _c.reviewAgain,
              child: Text(l10n.pilotImportReviewAgain),
            )
          else if (_c.canChooseAgain)
            FilledButton(
              key: const ValueKey('pilot-import-choose-again'),
              onPressed: _c.reviewAgain,
              child: Text(l10n.pilotImportChooseAgain),
            ),
        ];
    }
  }
}

/// The review of the pilots a file holds: new, updated and "maybe" ones,
/// each with its choice. Shared by the pilot and the competition import.
class PilotImportReviewList extends StatelessWidget {
  const PilotImportReviewList({super.key, required this.controller});

  final PilotImportController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final review = controller.review!;
    final draft = review.draft;
    final news = <int>[], updates = <int>[], maybes = <int>[];
    for (var i = 0; i < review.matches.length; i++) {
      final match = review.matches[i];
      if (match.isDuplicateInFile || match.kind == PilotMatchKind.likely) {
        maybes.add(i);
      } else if (match.kind == PilotMatchKind.exact) {
        updates.add(i);
      } else {
        news.add(i);
      }
    }
    final notes = _notes(context, l10n, draft);
    if (review.matches.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pilotImportNoPilots,
            key: const ValueKey('pilot-import-empty'),
          ),
          ...notes,
        ],
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 460),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(l10n.pilotImportReviewIntro),
          ...notes,
          if (maybes.isNotEmpty) ...[
            _heading(context, l10n.pilotImportMaybeHeading(maybes.length)),
            Text(
              l10n.pilotImportMaybeHint,
              key: const ValueKey('pilot-import-maybe-hint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            for (final i in maybes) _MaybeRow(controller: controller, index: i),
          ],
          if (updates.isNotEmpty) ...[
            _heading(context, l10n.pilotImportUpdateHeading(updates.length)),
            for (final i in updates)
              _CheckRow(controller: controller, index: i),
          ],
          if (news.isNotEmpty) ...[
            _heading(context, l10n.pilotImportNewHeading(news.length)),
            for (final i in news) _CheckRow(controller: controller, index: i),
          ],
        ],
      ),
    );
  }

  static Widget _heading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );

  List<Widget> _notes(
    BuildContext context,
    AppLocalizations l10n,
    PilotImportDraft draft,
  ) {
    final style = Theme.of(context).textTheme.bodySmall;
    final skipped = draft.skipped.length;
    final noCountry = draft.pilots
        .where((p) => p.warnings.any((w) => w.code.startsWith('country_')))
        .length;
    final dropped = [
      for (final entry in draft.droppedFieldCounts.entries)
        if (entry.value > 0) entry.key,
    ];
    final lines = <String>[
      if (draft.warnings.any((w) => w.code == PilotImportWarning.rowsTruncated))
        l10n.pilotImportTruncated,
      if (draft.excludedTestUsers > 0)
        l10n.pilotImportTestPilots(draft.excludedTestUsers),
      if (skipped > 0) l10n.pilotImportSkippedRows(skipped),
      if (noCountry > 0) l10n.pilotImportCountryNote(noCountry),
      if (dropped.isNotEmpty)
        l10n.pilotImportDroppedDetails(dropped.join(', ')),
    ];
    return [
      for (final line in lines)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(line, style: style),
        ),
    ];
  }
}

String _details(PilotDraft p) => [
  if (p.email != null) p.email!,
  if (p.club != null) p.club!,
  [?p.city, ?p.state].join(', '),
  if (p.country != null) p.country!,
].where((s) => s.isNotEmpty).join(' · ');

String _fieldName(AppLocalizations l10n, String field) => switch (field) {
  'email' => l10n.pilotImportFieldEmail,
  'faiNumber' => l10n.pilotImportFieldFai,
  'nationalOrgId' => l10n.pilotImportFieldNationalId,
  'club' => l10n.pilotImportFieldClub,
  'city' => l10n.pilotImportFieldCity,
  'state' => l10n.pilotImportFieldState,
  'country' => l10n.pilotImportFieldCountry,
  _ => field,
};

/// A new pilot or one that matches a participant: include or leave out.
class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.controller, required this.index});

  final PilotImportController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selection = controller.selections[index];
    final match = selection.match;
    final draft = match.draft;
    final no = draft.sourcePilotNo;
    final exact = match.kind == PilotMatchKind.exact;
    final included = selection.choice != PilotImportChoice.skip;
    final details = _details(draft);
    final note = !exact
        ? null
        : match.changes.isEmpty
        ? l10n.pilotImportNothingNew
        : l10n.pilotImportWillUpdate(
            match.changes.map((c) => _fieldName(l10n, c.field)).join(', '),
          );
    return CheckboxListTile(
      key: ValueKey('pilot-import-row-$no'),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      value: included,
      onChanged: (value) => controller.choose(
        index,
        value == true
            ? (exact ? PilotImportChoice.update : PilotImportChoice.add)
            : PilotImportChoice.skip,
      ),
      title: Text('${draft.firstName} ${draft.lastName}'),
      subtitle: Text([?note, if (details.isNotEmpty) details].join('\n')),
    );
  }
}

/// A pilot who might be a participant already: a person decides.
class _MaybeRow extends StatelessWidget {
  const _MaybeRow({required this.controller, required this.index});

  final PilotImportController controller;
  final int index;

  static const _skip = 'skip';
  static const _add = 'add';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selection = controller.selections[index];
    final match = selection.match;
    final draft = match.draft;
    final review = controller.review!;
    final no = draft.sourcePilotNo;
    final current = switch (selection.choice) {
      PilotImportChoice.skip => _skip,
      PilotImportChoice.add => _add,
      PilotImportChoice.update => 'update:${selection.targetProfileId?.value}',
    };
    final notes = [
      if (match.conflict) l10n.pilotImportConflict,
      if (match.isDuplicateInFile) l10n.pilotImportDuplicateInFile,
      _details(draft),
    ].where((s) => s.isNotEmpty).join('\n');
    return ListTile(
      key: ValueKey('pilot-import-row-$no'),
      dense: true,
      title: Text('${draft.firstName} ${draft.lastName}'),
      subtitle: notes.isEmpty ? null : Text(notes),
      trailing: SizedBox(
        width: 180,
        child: DropdownButton<String>(
          key: ValueKey('pilot-import-choice-$no'),
          isExpanded: true,
          value: current,
          onChanged: (value) {
            if (value == null) return;
            if (value == _skip) {
              controller.choose(index, PilotImportChoice.skip);
            } else if (value == _add) {
              controller.choose(index, PilotImportChoice.add);
            } else {
              controller.choose(
                index,
                PilotImportChoice.update,
                target: Id.parse(value.substring('update:'.length)),
              );
            }
          },
          items: [
            DropdownMenuItem(
              value: _skip,
              child: Text(
                l10n.pilotImportChoiceSkip,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: _add,
              child: Text(
                l10n.pilotImportChoiceAdd,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            for (final id in match.candidateIds)
              DropdownMenuItem(
                value: 'update:${id.value}',
                child: Tooltip(
                  message: l10n.pilotImportChoiceUpdate(
                    _name(review.profile(id)),
                  ),
                  child: Text(
                    l10n.pilotImportChoiceUpdate(_name(review.profile(id))),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _name(ParticipantProfile? p) =>
      p == null ? '?' : '${p.firstName} ${p.lastName}';
}
