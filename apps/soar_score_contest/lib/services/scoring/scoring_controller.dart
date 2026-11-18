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
    syncRefreshFailed = false;
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
    // A sync that came in meanwhile may be newer than what the load read.
    if (_refreshAfterLoad) {
      _refreshAfterLoad = false;
      if (loadError == null) await refreshAfterSync();
    }
  }

  bool _refreshAfterLoad = false;

  /// Counts stored entries, so a read can tell a save answered meanwhile.
  int _savedEpoch = 0;

  /// Reads the contest's scores again after a sync, without disturbing the
  /// page: the round and group stay, and nothing the director typed is lost.
  ///
  /// A row with unsaved edits keeps them; when its official score moved on
  /// meanwhile, the row is marked stale with the newer values, which is the
  /// same choice (keep mine or take theirs) a conflicting save leads to. A row
  /// being saved is left alone until its save answers. Every other row shows
  /// what was pulled, including a pilot's new submission. A failed read leaves
  /// the rows as they were and shows the refresh-failed notice with a Retry.
  Future<void> refreshAfterSync() async {
    // One read at a time: a sync that arrives meanwhile asks for one more
    // read after this one, so an older answer never lands over a newer one.
    if (_refreshing) {
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _refreshAgain = false;
        await _refreshOnce();
      } while (_refreshAgain && !_disposed);
    } finally {
      _refreshing = false;
    }
  }

  /// Whether [loadError] comes from a read after a sync that failed. Its
  /// Retry must be [refreshAfterSync] again, not [refresh]: only that keeps
  /// what was typed and marks a row another device saved meanwhile as stale,
  /// where [refresh] would rebase the typed values onto the newer score.
  bool syncRefreshFailed = false;

  bool _refreshing = false;
  bool _refreshAgain = false;

  Future<void> _refreshOnce() async {
    if (loading) {
      _refreshAfterLoad = true;
      return;
    }
    if (data == null) return;
    ScoringPageData? loaded;
    try {
      // A save that answers while the read is out makes the read older than
      // the page, so the read is made again rather than put over the save.
      for (var tries = 0; tries < 3 && loaded == null; tries++) {
        final epoch = _savedEpoch;
        final read = await ScoringPageData.load(client, contestId);
        if (epoch == _savedEpoch) loaded = read;
      }
    } on Object catch (error) {
      // The page keeps its rows, but says they may be behind: a sync reported
      // news and the later checks will not repeat it.
      if (!_disposed && data != null) {
        loadError = error;
        syncRefreshFailed = true;
        notifyListeners();
      }
      return;
    }
    if (loaded == null) return;
    if (_disposed || data == null) return;
    loadError = null;
    syncRefreshFailed = false;
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
      // Raw text counts, so an invalid entry is not wiped by a refresh.
      final typed = draft.editedSinceLoad;
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
    _syncReads++;
    await _loadResults();
    notifyListeners();
  }

  /// How many sync refreshes have been applied; a mark that was out while one
  /// was applied reads its slot again after its receipt, because the refresh
  /// kept the busy row as it was and the service may have decided meanwhile.
  int _syncReads = 0;

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
        (row.isOfficial
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

  /// Shows [queued] on [row]: the pilot's entry and the score stay as they
  /// were, and the slot holds the adoption waiting for the service.
  void _applyQueued(ScoringRow row, PendingPromotion queued) {
    // A sync read that began before the intent was queued is older than the
    // page now; the epoch makes it be read again instead of put over this.
    _savedEpoch++;
    final slot = row.slot!;
    data = data!.withSlot(
      ScoreSlot(
        placeholder: slot.placeholder,
        officialScore: slot.officialScore,
        pendingAttempt: slot.pendingAttempt,
        pendingPromotion: queued,
      ),
    );
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
      syncRefreshFailed = false;
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

  // Marking official.

  /// Whether the director typed over the form of [row], as opposed to the
  /// form still holding what the pilot submitted.
  bool hasEdits(ScoringRow row) {
    final draft = _drafts[row.id];
    return draft != null && draft.isDirty && !draft.isUntouchedPrefill;
  }

  /// Why [row] cannot be marked official now, or null when it can.
  ///
  /// A row with a review open can be marked on its own (the director decides
  /// that row), but "Mark all valid rows" holds it back: [forGroup] says
  /// which of the two is asked.
  MarkOfficialSkip? markOfficialSkip(ScoringRow row, {bool forGroup = false}) {
    if (!row.hasPendingSubmission || row.slot?.pendingAttempt == null) {
      return MarkOfficialSkip.noSubmission;
    }
    if (row.retired) return MarkOfficialSkip.retired;
    if (row.isAdoptionPending) return MarkOfficialSkip.waitingToSync;
    if (block != null || row.isLocked) return MarkOfficialSkip.closed;
    if (saveOf(row.id).isBusy) return MarkOfficialSkip.busy;
    if (hasEdits(row)) return MarkOfficialSkip.edited;
    if (forGroup &&
        row.slot?.placeholder.state == ScorePlaceholderState.inReview) {
      return MarkOfficialSkip.inReview;
    }
    return null;
  }

  /// The rows "Mark all valid rows official" would send.
  List<ScoringRow> get markAllRows => [
    for (final row in rows)
      if (markOfficialSkip(row, forGroup: true) == null) row,
  ];

  /// How many rows of the group hold a waiting submission, valid or not.
  int get waitingCount => rows.where((r) => r.hasPendingSubmission).length;

  /// Rows with a waiting submission that "Mark all" leaves out, by reason.
  Map<MarkOfficialSkip, int> get markAllSkipped {
    final skipped = <MarkOfficialSkip, int>{};
    for (final row in rows) {
      if (!row.hasPendingSubmission) continue;
      final why = markOfficialSkip(row, forGroup: true);
      if (why != null && why != MarkOfficialSkip.noSubmission) {
        skipped.update(why, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    return skipped;
  }

  /// Accepts the pilot's waiting submission of [row] as its official score.
  /// Returns whether the row is official now (a repeat of an accepted
  /// adoption counts).
  ///
  /// The request names the submission and score revision the director saw, so
  /// a pilot who changed their entry, or a score saved meanwhile, is refused
  /// and the row shows the newer values. A busy server (503) is "try again",
  /// not a failed save.
  Future<bool> markOfficial(ScoringRow row) async {
    if (markOfficialSkip(row) != null) return false;
    return _sendPromotion(row, row.slot!.pendingAttempt!.id.value);
  }

  /// Why the director cannot confirm the automatic score of [row] now, or
  /// null when they can. A row that is not an unconfirmed automatic score
  /// answers [MarkOfficialSkip.noSubmission].
  MarkOfficialSkip? confirmAutomaticSkip(ScoringRow row) {
    if (!row.isAutomaticUnconfirmed) return MarkOfficialSkip.noSubmission;
    if (row.isAdoptionPending) return MarkOfficialSkip.waitingToSync;
    if (block != null || row.isLocked) return MarkOfficialSkip.closed;
    if (saveOf(row.id).isBusy) return MarkOfficialSkip.busy;
    if (hasEdits(row)) return MarkOfficialSkip.edited;
    return null;
  }

  /// Confirms the score the contest accepted automatically for [row]: the
  /// director's decision is recorded and review closes for it, with no second
  /// official version. Asked like Mark official, naming the official score
  /// and its revision, so a change meanwhile is refused and shown. Returns
  /// whether the row is confirmed (a repeat counts).
  Future<bool> confirmAutomatic(ScoringRow row) async {
    if (confirmAutomaticSkip(row) != null) return false;
    return _sendPromotion(
      row,
      row.slot!.officialScore!.scoreAttemptId.value,
      confirm: true,
    );
  }

  /// The "mark official" request of [row] for [attemptId]: a waiting
  /// submission, or, for [confirm], the automatic official score itself.
  Future<bool> _sendPromotion(
    ScoringRow row,
    String attemptId, {
    bool confirm = false,
  }) async {
    _saves[row.id] = RowSave(
      RowSaveKind.saving,
      promotion: true,
      confirm: confirm,
    );
    notifyListeners();
    final readsBefore = _syncReads;
    try {
      final promoted = await client.promoteScore(
        contestId,
        row.id,
        PromoteScoreRequest(
          sourceAttemptId: attemptId,
          expectedScoreRevision: row.baseRevision,
        ),
      );
      final adopted = promoted.adopted;
      if (adopted == null) {
        // Queued for the service to decide: only the waiting adoption shows.
        // The receipt carries it, so a failed score read cannot hide it.
        _saves.remove(row.id);
        _applyQueued(row, promoted.queued!);
        notifyListeners();
        if (_syncReads != readsBefore) await _reconcile([row]);
        return true;
      }
      _applySaved(row, adopted.entry);
      recalculationWarning = adopted.entry.recalculationWarning;
      notifyListeners();
      await _loadResults();
      notifyListeners();
      return true;
    } on ApiHttpError catch (error) {
      final refusal = _promotionRefusal(
        error.statusCode,
        error.error?.code,
        error.error?.message,
        confirm: confirm,
      );
      _saves[row.id] = refusal;
      if (refusal.changed) {
        _settleChanged([row], await _refreshSlots([row]));
      }
    } on ApiNetworkError {
      _saves[row.id] = RowSave(
        RowSaveKind.failed,
        networkProblem: true,
        promotion: true,
        confirm: confirm,
      );
    } on Object catch (error) {
      _saves[row.id] = RowSave(
        RowSaveKind.failed,
        message: '$error',
        promotion: true,
        confirm: confirm,
      );
    }
    notifyListeners();
    return false;
  }

  static RowSave _promotionRefusal(
    int? status,
    String? code,
    String? message, {
    bool confirm = false,
  }) {
    if (status == 409 && code == 'stale_revision') {
      return RowSave(
        RowSaveKind.refused,
        promotion: true,
        changed: true,
        confirm: confirm,
      );
    }
    if (status == 503) {
      // A lock the server could not take in time: nothing was stored.
      return RowSave(
        RowSaveKind.failed,
        networkProblem: true,
        promotion: true,
        confirm: confirm,
      );
    }
    if (status == 409 || status == 400) {
      return RowSave(
        RowSaveKind.refused,
        message: message,
        promotion: true,
        confirm: confirm,
      );
    }
    return RowSave(
      RowSaveKind.failed,
      message: message ?? 'The server failed ($status).',
      promotion: true,
      confirm: confirm,
    );
  }

  /// Marks every valid row of the group official in one request (several of
  /// 100 at most), each row on its own outcome: a row that changed, is locked
  /// or hit a busy server keeps its message and the others still go through.
  Future<MarkAllSummary> markAllOfficial() async {
    final batch = markAllRows;
    final skipped = markAllSkipped;
    if (batch.isEmpty) return MarkAllSummary(skipped: skipped);
    final current = currentRound;
    if (current == null) return MarkAllSummary(skipped: skipped);
    for (final row in batch) {
      _saves[row.id] = const RowSave(RowSaveKind.saving, promotion: true);
    }
    notifyListeners();
    final readsBefore = _syncReads;
    var adopted = 0;
    var replayed = 0;
    var changed = 0;
    var refused = 0;
    var retry = 0;
    final moved = <ScoringRow>[];
    final waiting = <ScoringRow>[];
    for (
      var from = 0;
      from < batch.length;
      from += PromoteGroupRequest.maxItems
    ) {
      final chunk = batch.sublist(
        from,
        min(from + PromoteGroupRequest.maxItems, batch.length),
      );
      try {
        final answer = await client.promoteGroup(
          contestId,
          current.id,
          group,
          PromoteGroupRequest(
            items: [
              for (final row in chunk)
                PromoteGroupItem(
                  assignmentId: row.id.value,
                  sourceAttemptId: row.slot!.pendingAttempt!.id.value,
                  expectedScoreRevision: row.baseRevision,
                ),
            ],
          ),
        );
        final byId = {for (final o in answer.outcomes) o.assignmentId: o};
        for (final row in chunk) {
          final outcome = byId[row.id];
          final promotion = outcome?.promotion;
          if (promotion != null) {
            _applySaved(row, promotion.entry);
            promotion.replayed ? replayed++ : adopted++;
          } else if (outcome?.isQueued ?? false) {
            // Waiting for the service: show the adoption from its receipt.
            _saves.remove(row.id);
            _applyQueued(row, outcome!.queued!);
            waiting.add(row);
          } else if (outcome == null) {
            _saves[row.id] = const RowSave(
              RowSaveKind.failed,
              networkProblem: true,
              promotion: true,
            );
            retry++;
          } else {
            final refusal = _promotionRefusal(
              outcome.statusCode,
              outcome.code,
              outcome.message,
            );
            _saves[row.id] = refusal;
            if (refusal.changed) {
              moved.add(row);
              changed++;
            } else if (refusal.kind == RowSaveKind.failed) {
              retry++;
            } else {
              refused++;
            }
          }
        }
        if (answer.recalculationWarning != null) {
          recalculationWarning = answer.recalculationWarning;
        }
      } on Object catch (error) {
        final unreachable =
            error is ApiNetworkError ||
            (error is ApiHttpError && error.statusCode == 503);
        // Any other whole-request failure keeps the server's words and
        // offers Refresh; it is still counted as rows to try again.
        final said = error is ApiHttpError
            ? error.error?.message ?? 'The server failed (${error.statusCode}).'
            : '$error';
        for (final row in chunk) {
          _saves[row.id] = RowSave(
            RowSaveKind.failed,
            message: unreachable ? null : said,
            networkProblem: unreachable,
            promotion: true,
          );
        }
        retry += chunk.length;
      }
    }
    if (moved.isNotEmpty) {
      changed -= _settleChanged(moved, await _refreshSlots(moved));
    }
    if (waiting.isNotEmpty && _syncReads != readsBefore) {
      await _reconcile(waiting);
    }
    if (adopted + replayed > 0) {
      notifyListeners();
      await _loadResults();
    }
    notifyListeners();
    return MarkAllSummary(
      adopted: adopted,
      queued: waiting.length,
      replayed: replayed,
      changed: changed,
      refused: refused,
      retry: retry,
      skipped: skipped,
    );
  }

  /// After rows were refused as changed and their slots were read again
  /// ([read] says whether that worked): a row whose newer values could not
  /// be read offers Refresh, and a row that no longer waits, because another
  /// operator already made it official (or already decided an automatic
  /// score), has nothing left to ask. Returns how
  /// many rows were settled that way.
  /// Whether [row], read again, still asks the director for the decision it
  /// asked for: a waiting submission, or an automatic score to confirm.
  bool _stillWaiting(ScoringRow row) {
    final now = _rowOf(row.id);
    return row.isAutomaticUnconfirmed
        ? now?.isAutomaticUnconfirmed ?? false
        : now?.hasPendingSubmission ?? false;
  }

  int _settleChanged(List<ScoringRow> changed, bool read) {
    var settled = 0;
    for (final row in changed) {
      if (!read) {
        _saves[row.id] = const RowSave(RowSaveKind.failed, promotion: true);
      } else if (!_stillWaiting(row)) {
        _saves.remove(row.id);
        settled++;
      }
    }
    return settled;
  }

  /// After a sync was applied while a mark was out: reads the queued [rows]
  /// again, since the service may have decided them meanwhile. A failed read
  /// keeps the receipts shown and offers the sync-refresh Retry, which reads
  /// the whole page again.
  Future<void> _reconcile(List<ScoringRow> queued) async {
    if (await _refreshSlots(queued)) {
      notifyListeners();
      return;
    }
    if (_disposed) return;
    loadError = _slotReadError ?? StateError('The scores could not be read.');
    syncRefreshFailed = true;
    notifyListeners();
  }

  Object? _slotReadError;

  /// Reads the slots of [stale] again and shows their newer values, keeping
  /// whatever the director typed in a row.
  ///
  /// Returns false when the read failed and the rows are as they were.
  Future<bool> _refreshSlots(List<ScoringRow> stale) async {
    try {
      final fresh = await client.scores(contestId);
      final ids = {for (final row in stale) row.id};
      for (final slot in fresh.slots) {
        if (!ids.contains(slot.placeholder.assignmentId)) continue;
        data = data!.withSlot(slot);
      }
      for (final row in rows) {
        if (!ids.contains(row.id) || hasEdits(row)) continue;
        _drafts[row.id]?.resetTo(row.savedComponents, shown: _shown(row));
      }
      return true;
    } on Object catch (error) {
      _slotReadError = error;
      return false;
    }
  }

  ScoringRow? _rowOf(Id id) => rows.where((r) => r.id == id).firstOrNull;

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
    final inputs = <CheckInput>[];
    for (final row in rows.where((r) => !r.isMissed)) {
      final draft = _drafts[row.id];
      final components = draft?.components ?? row.formComponents;
      // A waiting submission with no values (its attempt not loaded) is not
      // an entry.
      inputs.add(
        CheckInput(
          rowKey: row.id.value,
          pilot: row.pilot.name,
          components: components,
          entered:
              (row.isEntered && components.isNotEmpty) ||
              (draft != null && !draft.isBlank),
        ),
      );
    }
    check = runScoreCheck(inputs);
    notifyListeners();
  }

  void clearCheck() {
    check = null;
    notifyListeners();
  }
}

/// Why a row is not marked official.
enum MarkOfficialSkip {
  /// No pilot submission waits on the row.
  noSubmission,

  /// The pilot retired from the round.
  retired,

  /// The adoption is queued on this device until the service decides it.
  waitingToSync,

  /// Entry is closed or the score is locked.
  closed,

  /// A save or promotion of the row is in flight.
  busy,

  /// The director typed over the pilot's values; save or revert first.
  edited,

  /// A review of the submission is open ("Mark all" holds it back).
  inReview,
}

/// What one "Mark all valid rows official" did.
class MarkAllSummary {
  const MarkAllSummary({
    this.adopted = 0,
    this.queued = 0,
    this.replayed = 0,
    this.changed = 0,
    this.refused = 0,
    this.retry = 0,
    this.skipped = const {},
  });

  /// Rows made official now.
  final int adopted;

  /// Rows whose adoption waits for the service to decide it.
  final int queued;

  /// Rows that already were official from this very submission.
  final int replayed;

  /// Rows whose submission or score changed since the page loaded.
  final int changed;

  /// Rows the server refused (locked, invalid).
  final int refused;

  /// Rows to try again: the server was busy or unreachable.
  final int retry;

  /// Rows left out before asking, by reason.
  final Map<MarkOfficialSkip, int> skipped;

  /// Rows that are official after the request.
  int get official => adopted + replayed;

  /// Whether no row is official after the request.
  bool get nothingAccepted => official == 0 && queued == 0;
}
