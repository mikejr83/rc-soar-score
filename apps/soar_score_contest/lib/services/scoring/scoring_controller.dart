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
/// official revision and a conflict or failure stays with its row.
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
    )..addListener(notifyListeners);
    return _drafts[row.id] = draft;
  }

  RowSave saveOf(Id id) => _saves[id] ?? RowSave.idle;

  /// What the other operator or the participant saved, for a stale row.
  Map<String, Object?>? theirsOf(Id id) => _theirs[id];

  bool isDirty(ScoringRow row) {
    final draft = _drafts[row.id];
    return draft != null && draft.isDirty;
  }

  int get dirtyCount => rows.where(isDirty).length;
  bool get hasUnsaved => dirtyCount > 0;

  // Navigation.

  /// Moves to [toRound] and [toGroup]. The caller has dealt with unsaved
  /// edits first.
  Future<void> open(int toRound, int toGroup) async {
    _drafts.clear();
    _saves.clear();
    _theirs.clear();
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
    for (final row in rows) {
      _drafts[row.id]?.resetTo(row.savedComponents);
    }
    _drafts.clear();
    _saves.clear();
    _theirs.clear();
    notifyListeners();
  }

  /// Puts one row back to what is saved.
  void revert(ScoringRow row) {
    _drafts[row.id]?.resetTo(row.savedComponents);
    _saves.remove(row.id);
    _theirs.remove(row.id);
    notifyListeners();
  }

  // Saving.

  /// Saves one row as its own official revision. Returns whether it saved.
  Future<bool> save(ScoringRow row, {String? reason}) async {
    final draft = draftOf(row);
    if (saveOf(row.id).isBusy || draft.problems.isNotEmpty) return false;
    if (draft.needsZeroConfirmation && !draft.zeroConfirmed) return false;
    _saves[row.id] = RowSave.saving;
    notifyListeners();
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
          reason:
              reason ??
              (row.isScored
                  ? 'Corrected on the scoring page'
                  : 'Entered on the scoring page'),
        ),
      );
      _mutationIds.remove(row.id);
      final slot = ScoreSlot(
        placeholder: result.placeholder,
        officialScore: result.officialScore,
      );
      data = data!.withSlot(slot).withContest(result.contest);
      _drafts[row.id]?.resetTo(result.officialScore.components);
      _saves.remove(row.id);
      _theirs.remove(row.id);
      recalculationWarning = result.recalculationWarning;
      notifyListeners();
      await _loadResults();
      notifyListeners();
      return true;
    } on ApiHttpError catch (error) {
      final code = error.error?.code;
      if (error.statusCode == 409 && code == 'stale_revision') {
        await _markStale(row);
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

  /// Saves every dirty row, each as its own revision, stopping at none: a
  /// failed row keeps its message and the others still save.
  Future<int> saveAll() async {
    var saved = 0;
    for (final row in rows.where(isDirty).toList()) {
      final draft = draftOf(row);
      if (draft.problems.isNotEmpty) continue;
      if (draft.needsZeroConfirmation) draft.confirmZero();
      if (await save(row)) saved++;
    }
    return saved;
  }

  Future<void> _markStale(ScoringRow row) async {
    try {
      final fresh = await client.scores(contestId);
      for (final slot in fresh.slots) {
        if (slot.placeholder.assignmentId == row.id) {
          data = data!.withSlot(slot);
          _theirs[row.id] = slot.officialScore?.components ?? const {};
        }
      }
    } on Object {
      // The conflict is still shown; the other values may be missing.
    }
    _saves[row.id] = const RowSave(
      RowSaveKind.stale,
      message: 'This row changed since you opened it.',
    );
  }

  /// Keeps the typed values over the newer revision, then saves again.
  Future<bool> keepMine(ScoringRow row) async {
    final fresh = rows.firstWhere((r) => r.id == row.id, orElse: () => row);
    _saves.remove(row.id);
    _theirs.remove(row.id);
    return save(fresh, reason: 'Kept the entered values over a newer revision');
  }

  /// Drops the typed values and shows the newer revision.
  void takeTheirs(ScoringRow row) {
    final fresh = rows.firstWhere((r) => r.id == row.id, orElse: () => row);
    _drafts[row.id]?.resetTo(fresh.savedComponents);
    _saves.remove(row.id);
    _theirs.remove(row.id);
    notifyListeners();
  }

  /// Loads the contest again, keeping what was typed.
  Future<void> refresh() async {
    try {
      final loaded = await ScoringPageData.load(client, contestId);
      data = loaded;
      for (final row in rows) {
        _drafts[row.id]?.rebase(row.savedComponents);
      }
      _saves.clear();
      await _loadResults();
    } on Object catch (error) {
      loadError = error;
    }
    notifyListeners();
  }

  // History.

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
    _drafts[row.id]?.resetTo(row.savedComponents);
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
