import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'pilot_history.dart';
import 'row_save.dart';
import 'score_check.dart';
import 'score_row_draft.dart';
import 'scoring_page_data.dart';
import 'scoring_row.dart';

/// State and actions of the scoring page: the loaded contest, the group in
/// view, a draft per pilot, and the save of each row.
///
/// Save is per row: one timekeeper slip is one pilot, so one save is one
/// official revision and a conflict or failure stays with its row. Saving
/// many rows at once is one bulk request that still answers per row.
class ScoringController extends ChangeNotifier {
  ScoringController({
    required this.client,
    required this.contestId,
    int? round,
    int? group,
  }) : _wantedRound = round,
       _wantedGroup = group;

  final ApiClient client;
  final Id contestId;
  final int? _wantedRound;
  final int? _wantedGroup;

  ScoringPageData? data;
  Object? loadError;
  bool loading = false;

  int round = 1;
  int group = 1;

  /// Calculated flights of the group in view, by participation id.
  Map<Id, FlightResult> results = const {};

  final Map<Id, ScoreRowDraft> _drafts = {};
  final Map<Id, RowSave> _saves = {};
  final Map<Id, Map<String, Object?>> _theirs = {};
  final Map<Id, String> _mutationIds = {};

  /// The correction reason recorded for a row whose pending save removes an
  /// applied cumulative penalty. It outlives a failed or stale save so a
  /// retry or a "Keep mine" re-uses it instead of a new or generic one.
  final Map<Id, String> _removalReasons = {};

  Id? activeId;

  /// Whether the keyboard path numbers are drawn over the controls.
  bool showFocusOrder = false;

  void toggleFocusOrder() {
    showFocusOrder = !showFocusOrder;
    notifyListeners();
  }

  ScoreCheckResult? check;

  /// The notice from the last save that the results are not up to date.
  String? recalculationWarning;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  // Loading.

  Future<void> load() async {
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      final loaded = await ScoringPageData.load(client, contestId);
      data = loaded;
      final open = loaded.firstOpen;
      final wantedRound = _wantedRound;
      if (wantedRound != null && loaded.roundByOrdinal(wantedRound) != null) {
        round = wantedRound;
        group = _wantedGroup ?? 1;
      } else {
        round = open.$1;
        group = open.$2;
      }
      _clampGroup();
      await _loadResults();
    } on Object catch (error) {
      loadError = error;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Reads the contest's scores again after a sync, without disturbing the
  /// page: the round and group stay, and nothing the director typed is lost.
  ///
  /// A row with unsaved edits keeps them; when its official score moved on
  /// meanwhile, the row is marked stale with the newer values, which is the
  /// same choice (keep mine or take theirs) a conflicting save leads to. A row
  /// being saved is left alone until its save answers. Every other row shows
  /// what was pulled, including a pilot's new submission. A failed read leaves
  /// the page as it was.
  /// Counts stored entries, so a read can tell a save answered meanwhile.
  int _savedEpoch = 0;

  Future<void> refreshAfterSync() async {
    if (data == null || loading) return;
    ScoringPageData? loaded;
    try {
      // A save that answers while the read is out makes the read older than
      // the page, so the read is made again rather than put over the save.
      for (var tries = 0; tries < 3 && loaded == null; tries++) {
        final epoch = _savedEpoch;
        final read = await ScoringPageData.load(client, contestId);
        if (epoch == _savedEpoch) loaded = read;
      }
    } on Object {
      return;
    }
    if (loaded == null) return;
    if (_disposed || data == null) return;
    final before = {for (final row in rows) row.id: row};
    var next = loaded;
    // A save in flight answers with its own copy of the slot.
    for (final row in before.values) {
      final slot = row.slot;
      if (saveOf(row.id).isBusy && slot != null) next = next.withSlot(slot);
    }
    data = next;
    _clampGroup();
    for (final row in rows) {
      if (saveOf(row.id).isBusy) continue;
      final draft = _drafts[row.id];
      if (draft == null) continue;
      final typed = draft.isDirty && !draft.isUntouchedPrefill;
      if (!typed) {
        draft.resetTo(row.savedComponents, shown: _shown(row));
      } else if (before[row.id]?.baseRevision != row.baseRevision) {
        _theirs[row.id] = row.savedComponents;
        _saves[row.id] = const RowSave(
          RowSaveKind.stale,
          message: 'This row changed since you opened it.',
        );
      }
    }
    await _loadResults();
    notifyListeners();
  }

  void _clampGroup() {
    final current = data?.roundByOrdinal(round);
    if (current != null && (group < 1 || group > current.groupCount)) {
      group = 1;
    }
  }

  Future<void> _loadResults() async {
    try {
      final loaded = await client.roundResults(contestId, round);
      results = {
        for (final flight in loaded.flights)
          if (flight.group == group) flight.participationId: flight.result,
      };
    } on Object {
      // Results are an extra: the page works without them.
      results = const {};
    }
  }

  // Views.

  Round? get currentRound => data?.roundByOrdinal(round);

  List<ScoringRow> get rows {
    final loaded = data;
    final current = currentRound;
    if (loaded == null || current == null) return const [];
    return loaded.rowsOf(current, group, results: results);
  }

  EntryBlock? get block {
    final loaded = data;
    final current = currentRound;
    if (loaded == null || current == null) return null;
    return loaded.block(current, group);
  }

  ScoreRowDraft draftOf(ScoringRow row) {
    final existing = _drafts[row.id];
    if (existing != null) return existing;
    // The page header counts unsaved rows, so it listens to every draft.
    final draft = ScoreRowDraft(
      settings: data!.settings,
      saved: row.savedComponents,
      shown: _shown(row),
    )..addListener(notifyListeners);
    return _drafts[row.id] = draft;
  }

  /// The pilot submission (attempt id) the director discarded or reverted, by
  /// row: the form shows what is saved instead of that submission. A different
  /// attempt, which means a newer submission, fills the form again.
  final Map<Id, Id> _prefillDismissed = {};

  void _dismissPrefill(ScoringRow row) {
    final attempt = row.slot?.pendingAttempt;
    if (row.hasPendingSubmission && attempt != null) {
      _prefillDismissed[row.id] = attempt.id;
    }
  }

  /// What [row]'s form starts with.
  Map<String, Object?> _shown(ScoringRow row) {
    final dismissed = _prefillDismissed[row.id];
    if (dismissed != null && dismissed == row.slot?.pendingAttempt?.id) {
      return row.savedComponents;
    }
    _prefillDismissed.remove(row.id);
    return row.formComponents;
  }

  RowSave saveOf(Id id) => _saves[id] ?? RowSave.idle;

  /// What the other operator or the participant saved, for a stale row.
  Map<String, Object?>? theirsOf(Id id) => _theirs[id];

  bool isDirty(ScoringRow row) {
    final draft = _drafts[row.id];
    return draft != null && draft.isDirty;
  }

  /// Rows being saved right now, one or many.
  int get savingCount => rows.where((r) => saveOf(r.id).isBusy).length;
  bool get isSaving => savingCount > 0;

  int get dirtyCount => rows.where(isDirty).length;
  bool get hasUnsaved => dirtyCount > 0;

  // Navigation.

  /// Moves to [toRound] and [toGroup]. The caller has dealt with unsaved
  /// edits first.
  Future<void> open(int toRound, int toGroup) async {
    _drafts.clear();
    _saves.clear();
    _theirs.clear();
    _removalReasons.clear();
    check = null;
    activeId = null;
    round = toRound;
    group = toGroup;
    _clampGroup();
    notifyListeners();
    await _loadResults();
    notifyListeners();
  }

  void activate(Id id) {
    if (activeId == id) return;
    activeId = id;
    notifyListeners();
  }

  void discardAll() {
    rows.forEach(_dismissPrefill);
    _drafts.clear();
    _saves.clear();
    _theirs.clear();
    _removalReasons.clear();
    notifyListeners();
  }

  /// Puts one row back to what is saved.
  void revert(ScoringRow row) {
    _dismissPrefill(row);
    _drafts[row.id]?.resetTo(row.savedComponents, shown: _shown(row));
    _saves.remove(row.id);
    _theirs.remove(row.id);
    _clearRemovalReason(row.id);
    notifyListeners();
  }

  // Saving.

  /// Whether saving this row removes an applied cumulative penalty
  /// (N → 0), an official correction that needs a recorded reason.
  bool isPenaltyRemoval(ScoringRow row) => _removal(row, _drafts[row.id]);

  /// The dirty rows whose save removes an applied cumulative penalty, in row
  /// order. Each needs a recorded reason the bulk paths must capture.
  List<ScoringRow> get removalRows {
    final removal = <ScoringRow>[];
    for (final row in rows) {
      final draft = _drafts[row.id];
      if (draft != null && _removal(row, draft)) removal.add(row);
    }
    return removal;
  }

  static bool _removal(ScoringRow row, ScoreRowDraft? draft) {
    if (draft == null || !draft.isDirty) return false;
    final saved = row.savedComponents['cumulative_penalty'];
    if (saved is! num || saved <= 0) return false;
    return draft.cumulativePenalty == 0;
  }

  /// The reason recorded with [row]'s save. A recorded removal reason
  /// belongs to the removal being saved; once the row is no longer a removal
  /// it no longer applies.
  String _reasonFor(ScoringRow row, String? reason) {
    if (isPenaltyRemoval(row)) {
      if (reason != null) _removalReasons[row.id] = reason;
    } else {
      _removalReasons.remove(row.id);
    }
    return reason ??
        _removalReasons[row.id] ??
        (row.isScored
            ? 'Corrected on the scoring page'
            : 'Entered on the scoring page');
  }

  /// Takes a stored entry into the page: the slot, the contest and the row's
  /// draft and save state.
  void _applySaved(ScoringRow row, ScoreEntryResult result) {
    _savedEpoch++;
    _mutationIds.remove(row.id);
    final slot = ScoreSlot(
      placeholder: result.placeholder,
      officialScore: result.officialScore,
    );
    data = data!.withSlot(slot).withContest(result.contest);
    _drafts[row.id]?.resetTo(result.officialScore.components);
    _saves.remove(row.id);
    _theirs.remove(row.id);
    // The row no longer removes a penalty, so its reason is done with.
    _clearRemovalReason(row.id);
  }

  /// Saves one row as its own official revision. Returns whether it saved.
  ///
  /// When the save removed an applied cumulative penalty, any earlier
  /// recorded removal reason is remembered on the row, so a retry or a
  /// "Keep mine" after a failure or conflict re-records it instead of
  /// asking again or falling back to a generic reason.
  Future<bool> save(ScoringRow row, {String? reason}) async {
    final draft = draftOf(row);
    if (saveOf(row.id).isBusy || draft.problems.isNotEmpty) return false;
    if (draft.needsZeroConfirmation && !draft.zeroConfirmed) return false;
    _saves[row.id] = RowSave.saving;
    notifyListeners();
    final effectiveReason = _reasonFor(row, reason);
    final mutationId = _mutationIds.putIfAbsent(
      row.id,
      () => Id.create().value,
    );
    try {
      final result = await client.enterScore(
        contestId,
        row.id,
        EnterScoreRequest(
          clientMutationId: mutationId,
          baseScoreRevision: row.baseRevision,
          components: draft.components,
          reason: effectiveReason,
        ),
      );
      _mutationIds.remove(row.id);
      _applySaved(row, result);
      recalculationWarning = result.recalculationWarning;
      notifyListeners();
      await _loadResults();
      notifyListeners();
      return true;
    } on ApiHttpError catch (error) {
      final code = error.error?.code;
      if (error.statusCode == 409 &&
          (code == 'stale_revision' || code == 'already_stored')) {
        // An existing attempt with this mutation id is not this save: the
        // next save must not replay it over what was typed.
        if (code == 'already_stored') _mutationIds.remove(row.id);
        await _markStale([row]);
      } else if (error.statusCode == 409 || error.statusCode == 400) {
        _mutationIds.remove(row.id);
        _saves[row.id] = RowSave(
          RowSaveKind.refused,
          message: error.error?.message ?? 'The entry was refused.',
        );
      } else {
        _saves[row.id] = RowSave(
          RowSaveKind.failed,
          message:
              error.error?.message ??
              'The server failed (${error.statusCode}).',
        );
      }
    } on ApiNetworkError {
      _saves[row.id] = const RowSave(
        RowSaveKind.failed,
        message: 'The server could not be reached. Your values are kept.',
        networkProblem: true,
      );
    } on Object catch (error) {
      _saves[row.id] = RowSave(RowSaveKind.failed, message: '$error');
    }
    notifyListeners();
    return false;
  }

  /// Dirty rows that [saveAll] would save as a zero the director has not
  /// confirmed yet (a motor restart, out of bounds or no altitude).
  List<ScoringRow> get unconfirmedZeroRows => [
    for (final row in rows.where(isDirty))
      if (!const {
            RowSaveKind.stale,
            RowSaveKind.saving,
          }.contains(saveOf(row.id).kind) &&
          draftOf(row).problems.isEmpty &&
          draftOf(row).needsZeroConfirmation &&
          !draftOf(row).zeroConfirmed)
        row,
  ];

  /// Saves every dirty row, each as its own revision, in ONE bulk request
  /// (one row goes through the single-row route). A row the server refuses
  /// keeps its message and the others still save; the results are loaded
  /// once at the end.
  ///
  /// Rows that went stale, or whose last save failed or was refused and
  /// removes an applied cumulative penalty, are left for the director to
  /// resolve on the row. A removal row is included only when its reason was
  /// recorded first ([recordRemovalReason]), so it is never saved under a
  /// generic reason.
  Future<int> saveAll() async {
    final batch = <ScoringRow>[];
    for (final row in rows.where(isDirty).toList()) {
      final kind = saveOf(row.id).kind;
      if (kind == RowSaveKind.stale || kind == RowSaveKind.saving) continue;
      if (isPenaltyRemoval(row)) {
        if (removalReason(row.id) == null ||
            kind == RowSaveKind.failed ||
            kind == RowSaveKind.refused) {
          continue;
        }
      }
      final draft = draftOf(row);
      if (draft.problems.isNotEmpty) continue;
      if (draft.needsZeroConfirmation) draft.confirmZero();
      batch.add(row);
    }
    if (batch.isEmpty) return 0;
    if (batch.length == 1) return await save(batch.single) ? 1 : 0;
    var saved = 0;
    for (
      var from = 0;
      from < batch.length;
      from += EnterScoresRequest.maxEntries
    ) {
      final chunk = batch.sublist(
        from,
        min(from + EnterScoresRequest.maxEntries, batch.length),
      );
      saved += await _saveBatch(chunk);
    }
    if (saved > 0) {
      await _loadResults();
      notifyListeners();
    }
    return saved;
  }

  /// Records the reason for removing [row]'s applied cumulative penalty, to
  /// be sent with its save.
  void recordRemovalReason(Id id, String reason) {
    _removalReasons[id] = reason;
  }

  Future<int> _saveBatch(List<ScoringRow> batch) async {
    final entries = <EnterScoresEntry>[];
    for (final row in batch) {
      _saves[row.id] = RowSave.saving;
      final reason = _reasonFor(row, null);
      entries.add(
        EnterScoresEntry(
          assignmentId: row.id,
          clientMutationId: _mutationIds.putIfAbsent(
            row.id,
            () => Id.create().value,
          ),
          baseScoreRevision: row.baseRevision,
          components: draftOf(row).components,
          reason: reason,
        ),
      );
    }
    notifyListeners();
    var saved = 0;
    try {
      final answer = await client.enterScores(
        contestId,
        EnterScoresRequest(entries: entries),
      );
      if (answer.results.length != batch.length) {
        throw StateError(
          'The server answered ${answer.results.length} '
          'results for ${batch.length} entries.',
        );
      }
      final stale = <ScoringRow>[];
      for (final (i, row) in batch.indexed) {
        final outcome = answer.results[i];
        final result = outcome.result;
        if (result != null) {
          _applySaved(row, result);
          saved++;
        } else if (outcome.statusCode == 409 &&
            (outcome.code == 'stale_revision' ||
                outcome.code == 'already_stored')) {
          if (outcome.code == 'already_stored') _mutationIds.remove(row.id);
          stale.add(row);
        } else if (outcome.statusCode == 409 || outcome.statusCode == 400) {
          _mutationIds.remove(row.id);
          _saves[row.id] = RowSave(
            RowSaveKind.refused,
            message: outcome.message ?? 'The entry was refused.',
          );
        } else {
          _saves[row.id] = RowSave(
            RowSaveKind.failed,
            message: outcome.message ?? 'The entry failed.',
          );
        }
      }
      if (saved > 0) recalculationWarning = answer.recalculationWarning;
      if (stale.isNotEmpty) await _markStale(stale);
    } on ApiHttpError catch (error) {
      if (error.statusCode == 404 || error.statusCode == 405) {
        // A server older than this app has no bulk route: save row by row.
        for (final row in batch) {
          _saves.remove(row.id);
        }
        for (final row in batch) {
          if (await save(row)) saved++;
        }
        notifyListeners();
        return saved;
      }
      _failAll(
        batch,
        RowSave(
          RowSaveKind.failed,
          message:
              error.error?.message ??
              'The server failed (${error.statusCode}).',
        ),
      );
    } on ApiNetworkError {
      _failAll(
        batch,
        const RowSave(
          RowSaveKind.failed,
          message: 'The server could not be reached. Your values are kept.',
          networkProblem: true,
        ),
      );
    } on Object catch (error) {
      _failAll(batch, RowSave(RowSaveKind.failed, message: '$error'));
    }
    notifyListeners();
    return saved;
  }

  void _failAll(List<ScoringRow> batch, RowSave failure) {
    for (final row in batch) {
      _saves[row.id] = failure;
    }
  }

  Future<void> _markStale(List<ScoringRow> stale) async {
    try {
      final fresh = await client.scores(contestId);
      final ids = {for (final row in stale) row.id};
      for (final slot in fresh.slots) {
        if (ids.contains(slot.placeholder.assignmentId)) {
          data = data!.withSlot(slot);
          _theirs[slot.placeholder.assignmentId] =
              slot.officialScore?.components ?? const {};
        }
      }
    } on Object {
      // The conflict is still shown; the other values may be missing.
    }
    for (final row in stale) {
      _saves[row.id] = const RowSave(
        RowSaveKind.stale,
        message: 'This row changed since you opened it.',
      );
    }
  }

  /// Keeps the typed values over the newer revision, then saves again.
  ///
  /// A removal re-records its stored reason instead of the generic
  /// conflict message: the director already said why the penalty is gone.
  Future<bool> keepMine(ScoringRow row) async {
    final fresh = rows.firstWhere((r) => r.id == row.id, orElse: () => row);
    _saves.remove(row.id);
    _theirs.remove(row.id);
    final reason =
        _removalReasons[fresh.id] ??
        'Kept the entered values over a newer revision';
    return save(fresh, reason: reason);
  }

  /// Drops the typed values and shows the newer revision.
  void takeTheirs(ScoringRow row) {
    final fresh = rows.firstWhere((r) => r.id == row.id, orElse: () => row);
    _prefillDismissed.remove(row.id);
    _drafts[row.id]?.resetTo(
      fresh.savedComponents,
      shown: fresh.formComponents,
    );
    _saves.remove(row.id);
    _theirs.remove(row.id);
    _clearRemovalReason(row.id);
    notifyListeners();
  }

  /// Loads the contest again, keeping what was typed.
  Future<void> refresh() async {
    try {
      final loaded = await ScoringPageData.load(client, contestId);
      data = loaded;
      loadError = null;
      for (final row in rows) {
        final draft = _drafts[row.id];
        if (draft == null) continue;
        // An untouched form follows the reload (a pilot may have submitted
        // since); what the director typed stays.
        if (draft.isDirty && !draft.isUntouchedPrefill) {
          draft.rebase(row.savedComponents);
        } else {
          draft.resetTo(row.savedComponents, shown: _shown(row));
        }
      }
      _saves.clear();
      // A reload that shows the penalty already removed settles the row.
      for (final row in rows) {
        if (!_removal(row, _drafts[row.id])) _clearRemovalReason(row.id);
      }
      await _loadResults();
    } on Object catch (error) {
      loadError = error;
    }
    notifyListeners();
  }

  // History.

  // Removal reasons.

  /// The recorded penalty-removal reason of a row still awaiting its save,
  /// or null. Kept through a failed, refused or stale save so a retry or a
  /// "Keep mine" re-records it.
  String? removalReason(Id id) => _removalReasons[id];

  void _clearRemovalReason(Id id) {
    _removalReasons.remove(id);
  }

  /// The history of one row, oldest first.
  Future<ScoreHistory> historyOf(ScoringRow row) =>
      client.scoreHistory(contestId, row.id);

  /// The history of every row of the group in view, as one list per pilot
  /// that has anything in it, in row order.
  Future<List<PilotHistory>> groupHistory() async {
    final shown = rows;
    final loaded = await Future.wait([for (final row in shown) historyOf(row)]);
    return [
      for (var i = 0; i < shown.length; i++)
        if (loaded[i].entries.isNotEmpty)
          PilotHistory(pilot: shown[i].pilot.name, entries: loaded[i].entries),
    ];
  }

  // Retirement.

  /// Why the pilots cannot be retired or reinstated now, or null. A completed
  /// or administration-locked contest takes no changes of who flies.
  String? get retireBlocked => switch (block) {
    EntryBlock.contestCompleted => 'Contest completed: retirement is closed',
    EntryBlock.administrationLocked =>
      'Administration locked: unlock to change retirement',
    _ => null,
  };

  ContestParticipation? _participation(Id id) {
    for (final p
        in data?.base.participations ?? const <ContestParticipation>[]) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Retires the pilot of [row] from the round in view on. Throws the API
  /// error when the server refuses; the page shows it.
  Future<void> retire(ScoringRow row) =>
      _setRetirement(row, retiredAtRound: round);

  /// Takes back the retirement of the pilot of [row].
  Future<void> reinstate(ScoringRow row) =>
      _setRetirement(row, retiredAtRound: null);

  Future<void> _setRetirement(ScoringRow row, {int? retiredAtRound}) async {
    final participation = _participation(row.pilot.participationId);
    if (participation == null) {
      throw StateError('The pilot is not in this contest.');
    }
    final updated = await client.updateParticipation(
      contestId,
      participation.id,
      UpdateParticipationRequest(
        baseRevision: participation.revision,
        classification: participation.classification,
        retiredAtRound: retiredAtRound,
      ),
    );
    _drafts[row.id]?.resetTo(row.savedComponents, shown: _shown(row));
    _saves.remove(row.id);
    await refresh();
    // refresh() does not touch the notice, so it shows after the reload.
    recalculationWarning = updated.recalculationWarning;
    notifyListeners();
  }

  // Score check.

  void runCheck() {
    check = runScoreCheck([
      for (final row in rows.where((r) => !r.isMissed))
        CheckInput(
          rowKey: row.id.value,
          pilot: row.pilot.name,
          components: _drafts[row.id]?.components ?? row.savedComponents,
          entered:
              row.isScored ||
              (_drafts[row.id] != null && !_drafts[row.id]!.isBlank),
        ),
    ]);
    notifyListeners();
  }

  void clearCheck() {
    check = null;
    notifyListeners();
  }
}
