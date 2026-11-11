import 'package:flutter/foundation.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_failure.dart';
import '../participants/participant_option.dart';
import '../participants/participant_row_style.dart';
import 'participants_page_data.dart';
import 'placement_report.dart';
import 'row_outcome.dart';
import 'stored_list_rules.dart';
import 'stored_participant.dart';

/// State and actions of the contest Participants page: the loaded people, the
/// director's unsaved edits, and the immediate actions (add, remove).
///
/// Edits to role, class and team are held per row until [save], which sends
/// each changed row on its own, so a failure or conflict stays with its row.
/// Adding and removing people take effect at once.
class ParticipantsController extends ChangeNotifier {
  ParticipantsController({required this.client, required this.contestId});

  final ApiClient client;
  final Id contestId;

  /// The longest team name the page accepts.
  static const int maxTeamName = 40;

  ParticipantsPageData? data;
  Object? loadError;
  bool loading = false;

  /// Whether a save is running (rows are locked meanwhile).
  bool saving = false;

  /// A sync arrived while saving; the list is read again once the save ends.
  bool _refreshAfterSave = false;

  /// The rows as stored, with the director's edits in [_drafts].
  List<StoredParticipant> _saved = const [];
  final Map<String, StoredParticipant> _drafts = {};
  final Map<String, RowState> _states = {};
  final Map<Id, Id> _addIds = {};
  List<Team> _teams = const [];

  /// The selected rows, by participation id.
  final Set<String> selection = {};

  /// The text in the search field, which filters the list.
  String query = '';

  /// The row to scroll to and highlight, after an add.
  String? highlightId;

  /// A short message for the snackbar.
  String? message;

  /// Who was affected by the last save in a running contest (`Ben Ortiz’s
  /// class`), so the page can say the results are recalculated.
  List<String> recalculated = const [];

  /// A recalculation notice from the server (the results read as stale).
  String? recalculationWarning;

  /// The last add that failed, so it can be tried again (idempotent).
  ParticipantProfile? failedAdd;
  Role? failedAddRole;
  String? addFailure;

  /// Whether the last failed add was refused because a round has no group
  /// with room, which trying again does not change until the groups do.
  bool addNeedsRoom = false;

  /// What the last removal left behind.
  RemoveResult? lastRemoval;

  /// People who left the draw since the page opened (removed, or changed to
  /// a non-flying role) while they had places in it but no scores. The draw
  /// then needs redoing, and the page says so until dismissed.
  List<String> leftTheDraw = const [];

  /// Where the last pilot added after the draw was put in the rounds.
  PlacementReport? lastPlacement;

  /// Pilots who joined after the draw (added, or changed from a non-flying
  /// role) and are not in the rounds yet, by participation id.
  final Set<String> _toPlace = {};

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

  // The contest.

  Contest? get contest => data?.contest;

  bool get readOnly => contest?.lifecycleState == LifecycleState.completed;

  bool get adminLocked => !readOnly && contest?.adminLock == AdminLock.locked;

  bool get running => contest?.lifecycleState == LifecycleState.running;

  bool get drawn => data?.drawn ?? false;

  /// Whether any pilot has a score in any round.
  bool get hasScores => data?.hasScores ?? false;

  /// Whether the people can be edited, added and removed.
  bool get canEdit => !readOnly && !adminLocked;

  Set<ParticipantOption> get options => data?.options ?? const {};

  List<Role> get roles => data?.roles ?? const [];

  // The rows.

  StoredParticipant? _savedRow(String id) =>
      _saved.where((row) => row.rowId == id).firstOrNull;

  /// The rows with the director's edits applied.
  List<StoredParticipant> get rows => [
    for (final row in _saved) _drafts[row.rowId] ?? row,
  ];

  late StoredListRules _rules = _makeRules();

  StoredListRules _makeRules() =>
      StoredListRules(options: options, rows: rows, drawn: drawn);

  /// The rules over the current rows.
  StoredListRules get rules => _rules;

  /// The rows that match [query] (name, email, team, class or role).
  List<StoredParticipant> get visibleRows {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) return rows;
    return [
      for (final row in rows)
        if ([
          row.name,
          row.email ?? '',
          row.team,
          row.classification,
          row.roleName,
        ].any((value) => value.toLowerCase().contains(text)))
          row,
    ];
  }

  int get scoringPilots => rows.where(rules.isScoring).length;

  int get nonFlying => rows.length - scoringPilots;

  /// Profile ids already in the contest.
  Set<String> get memberProfileIds => {
    for (final row in _saved) row.profile.id.value,
  };

  List<ParticipantProfile> get profiles => data?.base.profiles ?? const [];

  /// Whether the pilot has a score in any round.
  bool hasFlights(StoredParticipant row) =>
      rules.isScoring(row) && (data?.hasFlights(row.id) ?? false);

  /// Whether the matrix has a place for the pilot, who has no score. Removing
  /// them, or making them non-flying, takes those places out of the draw.
  bool inDraw(StoredParticipant row) =>
      rules.isScoring(row) && !hasFlights(row) && _hasMatrixRows(row);

  bool _hasMatrixRows(StoredParticipant row) =>
      data?.hasMatrixRows(row.id) ?? false;

  /// Pilots added after the draw and not in a group yet.
  List<StoredParticipant> get unplaced => [
    if (drawn)
      for (final row in rows)
        if (rules.isScoring(row) && row.number == null) row,
  ];

  /// Scoring pilots (or all, without roles) with no class, when classes are
  /// on. Nothing blocks on these, but the page lists them.
  List<StoredParticipant> get missingClass => [
    if (options.contains(ParticipantOption.classes))
      for (final row in rows)
        if (rules.issuesOf(row).isNotEmpty) row,
  ];

  RowState stateOf(String id) => _states[id] ?? const RowState(RowOutcome.none);

  // Loading.

  Future<void> load() async {
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      await _read();
    } on Object catch (error) {
      loadError = error;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Reads everything again, keeping the director's edits.
  Future<void> reload() async {
    try {
      await _read();
    } on Object catch (error) {
      message = 'The list could not be refreshed. ${apiErrorTextOf(error)}';
    }
    notifyListeners();
  }

  /// Reads everything again after a sync, keeping the director's edits and
  /// saying nothing when the read fails: the list stays as it was. Not while
  /// the page loads (which reads the list itself). During a save the read waits
  /// until the save ends.
  Future<void> refreshQuietly() async {
    if (data == null || loading) return;
    if (saving) {
      // The save does not read the list again, so it asks for this once done.
      _refreshAfterSave = true;
      return;
    }
    try {
      await _read();
    } on Object {
      return;
    }
    notifyListeners();
  }

  Future<void> _read() async {
    final loaded = await ParticipantsPageData.load(client, contestId);
    data = loaded;
    _teams = loaded.base.teams;
    _saved = loaded.participants;
    final ids = {for (final row in _saved) row.rowId};
    _drafts.removeWhere((id, _) => !ids.contains(id));
    // Models are saved on their own, so an edited row shows the fresh ones.
    for (final row in _saved) {
      final edited = _drafts[row.rowId];
      if (edited != null) _drafts[row.rowId] = edited.withModels(row.models);
    }
    _states.removeWhere((id, _) => !ids.contains(id));
    selection.retainAll(ids);
    _rules = _makeRules();
  }

  // Editing.

  /// Whether any row has unsaved edits.
  bool get hasUnsaved => changedIds.isNotEmpty;

  /// The rows with unsaved edits, in list order.
  List<String> get changedIds => [
    for (final row in _saved)
      if (cellsChanged(row.rowId).isNotEmpty) row.rowId,
  ];

  /// The cells of row [id] edited since the last save.
  Set<ParticipantCell> cellsChanged(String id) {
    final draft = _drafts[id];
    final saved = _savedRow(id);
    if (draft == null || saved == null) return const {};
    return draft.changedFrom(saved);
  }

  /// Replaces a row with [updated], an edited copy. An edit that returns the
  /// row to its saved values drops the draft.
  void edit(StoredParticipant updated) {
    final saved = _savedRow(updated.rowId);
    if (saved == null || saving || !canEdit) return;
    if (updated.changedFrom(saved).isEmpty) {
      _drafts.remove(updated.rowId);
    } else {
      _drafts[updated.rowId] = updated;
    }
    final state = _states[updated.rowId];
    if (state != null && state.outcome != RowOutcome.stale) {
      _states.remove(updated.rowId);
    }
    highlightId = null;
    recalculated = const [];
    _rules = _makeRules();
    notifyListeners();
  }

  /// Sets the team of the selected rows.
  void setTeamForSelected(String team) {
    for (final row in rows.where((r) => selection.contains(r.rowId))) {
      edit(row.withEdits(team: team));
    }
  }

  /// Sets the class of the selected scoring pilots.
  void setClassForSelected(String classification) {
    for (final row in rows.where((r) => selection.contains(r.rowId))) {
      if (rules.isScoring(row)) {
        edit(row.withEdits(classification: classification));
      }
    }
  }

  /// Sets the role of the selected rows. A pilot with flights cannot become
  /// non-flying, so those rows keep their role.
  void setRoleForSelected(Role role) {
    for (final row in rows.where((r) => selection.contains(r.rowId))) {
      if (role.type != RoleType.pilot && hasFlights(row)) continue;
      edit(row.withEdits(role: role));
    }
  }

  /// Throws away the edits of row [id].
  void undoRow(String id) {
    _drafts.remove(id);
    final state = _states[id];
    if (state != null && state.outcome != RowOutcome.stale) {
      _states.remove(id);
    }
    _rules = _makeRules();
    notifyListeners();
  }

  /// Throws away every unsaved edit and the failures of earlier saves.
  void discardAll() {
    _drafts.clear();
    _states.removeWhere((_, state) => state.outcome != RowOutcome.added);
    recalculated = const [];
    _rules = _makeRules();
    notifyListeners();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void toggleSelected(String id) {
    if (!selection.remove(id)) selection.add(id);
    notifyListeners();
  }

  void toggleAll(Iterable<String> ids) {
    final list = ids.toList();
    if (list.every(selection.contains)) {
      selection.removeAll(list);
    } else {
      selection.addAll(list);
    }
    notifyListeners();
  }

  void clearSelection() {
    selection.clear();
    notifyListeners();
  }

  void clearMessage() {
    message = null;
  }

  // Why Save is off.

  /// A changed row that cannot be saved as it is: a team name that is too
  /// long. A missing class never blocks (it is a notice only).
  bool isInvalid(StoredParticipant row) => teamTooLong(row);

  bool teamTooLong(StoredParticipant row) =>
      row.team.trim().length > maxTeamName;

  /// Changed rows that cannot be saved yet.
  List<StoredParticipant> get invalidChanged => [
    for (final row in rows)
      if (cellsChanged(row.rowId).isNotEmpty && isInvalid(row)) row,
  ];

  /// Rows that were changed elsewhere since the page read them.
  List<String> get staleIds => [
    for (final entry in _states.entries)
      if (entry.value.outcome == RowOutcome.stale) entry.key,
  ];

  /// Rows whose last save failed.
  List<StoredParticipant> get failedRows => [
    for (final row in _saved)
      if (stateOf(row.rowId).outcome == RowOutcome.failed) row,
  ];

  /// How many rows the last save stored.
  int get savedCount =>
      _states.values.where((state) => state.outcome == RowOutcome.saved).length;

  // Saving.

  /// Saves every changed row on its own.
  Future<void> save() async {
    if (saving || invalidChanged.isNotEmpty || staleIds.isNotEmpty) return;
    final ids = changedIds;
    if (ids.isEmpty) return;
    saving = true;
    recalculated = const [];
    recalculationWarning = null;
    for (final id in ids) {
      _states[id] = const RowState(RowOutcome.saving);
    }
    notifyListeners();
    var ok = 0;
    final left = <String>[];
    final touched = <String>[];
    final warnings = <String>{};
    for (final id in ids) {
      final saved = _savedRow(id)!;
      final draft = _drafts[id]!;
      final changed = draft.changedFrom(saved);
      final result = await _saveRow(saved, draft, changed);
      // A step that went through before a later one failed has already
      // changed the results, so its notice counts for a failed row too.
      if (result.warning != null) warnings.add(result.warning!);
      if (result.matrixRowsRemoved > 0) left.add(saved.name);
      if (result.failure == null) {
        ok++;
        // A non-flier who became a pilot after the draw joins the rounds.
        if (drawn && !saved.isPilot && draft.isPilot) _toPlace.add(id);
        if (running) touched.add(_recalcLabel(draft, changed));
        _states[id] = const RowState(RowOutcome.saved);
      } else {
        _states[id] = result.failure!;
      }
      notifyListeners();
    }
    saving = false;
    if (left.isNotEmpty) {
      leftTheDraw = [...leftTheDraw, ...left];
      try {
        await _read();
      } on Object {
        // The next load shows the matrix as it is.
      }
    }
    recalculated = touched;
    recalculationWarning = warnings.isEmpty ? null : warnings.join(' ');
    message = ok == 0 ? null : '$ok participant${ok == 1 ? '' : 's'} saved.';
    _rules = _makeRules();
    notifyListeners();
    if (_refreshAfterSave) {
      _refreshAfterSave = false;
      await refreshQuietly();
    }
  }

  String _recalcLabel(StoredParticipant row, Set<ParticipantCell> changed) {
    final what = changed.contains(ParticipantCell.role)
        ? 'role'
        : changed.contains(ParticipantCell.classification)
        ? 'class'
        : 'team';
    return '${row.name}’s $what';
  }

  Future<({RowState? failure, String? warning, int matrixRowsRemoved})>
  _saveRow(
    StoredParticipant saved,
    StoredParticipant draft,
    Set<ParticipantCell> changed,
  ) async {
    var participation = draft.participation;
    var membershipId = saved.membershipId;
    var team = saved.team;
    String? warning;
    var rowsRemoved = 0;
    // Keeps what already went through, so a retry starts from it.
    void remember() {
      final progress = StoredParticipant(
        participation: participation,
        profile: saved.profile,
        membershipId: membershipId,
        models: saved.models,
        team: team,
      );
      _replaceSaved(progress);
      final remaining = draft.changedFrom(progress);
      if (remaining.isEmpty) {
        _drafts.remove(saved.rowId);
      } else {
        _drafts[saved.rowId] = StoredParticipant(
          participation: participation,
          profile: draft.profile,
          membershipId: membershipId,
          models: saved.models,
          roleId: draft.roleId,
          roleName: draft.roleName,
          isPilot: draft.isPilot,
          classification: draft.classification,
          team: draft.team,
        );
      }
    }

    try {
      if (changed.contains(ParticipantCell.role) ||
          changed.contains(ParticipantCell.classification)) {
        final classification = draft.classification.trim();
        final result = await client.updateParticipation(
          contestId,
          saved.id,
          UpdateParticipationRequest(
            baseRevision: participation.revision,
            roleId: changed.contains(ParticipantCell.role)
                ? draft.roleId
                : null,
            classification: draft.isPilot && classification.isNotEmpty
                ? classification
                : null,
            retiredAtRound: participation.retiredAtRound,
          ),
        );
        participation = result.participation;
        warning = result.recalculationWarning;
        rowsRemoved = result.matrixRowsRemoved;
        remember();
      }
      if (changed.contains(ParticipantCell.team)) {
        final name = draft.team.trim();
        final teamId = name.isEmpty ? null : await _teamIdFor(name);
        if (membershipId != null) {
          warning =
              await client.removeTeamMember(contestId, membershipId) ?? warning;
          membershipId = null;
          team = '';
          remember();
        }
        if (teamId != null) {
          final membership = await client.addTeamMember(
            contestId,
            AddTeamMemberRequest(
              id: Id.create(),
              teamId: teamId,
              contestParticipationId: saved.id,
            ),
          );
          membershipId = membership.membership.id;
          warning = membership.recalculationWarning ?? warning;
          team = name;
          remember();
        }
      }
      remember();
      return (failure: null, warning: warning, matrixRowsRemoved: rowsRemoved);
    } on Object catch (error) {
      remember();
      final stale =
          error is ApiHttpError && error.error?.code == 'stale_revision';
      return (
        failure: RowState(
          stale ? RowOutcome.stale : RowOutcome.failed,
          message: apiErrorTextOf(error),
        ),
        warning: warning,
        matrixRowsRemoved: rowsRemoved,
      );
    }
  }

  void _replaceSaved(StoredParticipant row) {
    _saved = [for (final r in _saved) r.rowId == row.rowId ? row : r];
  }

  /// The id of the team called [name] (matched ignoring case), creating it
  /// when the contest has none of that name.
  Future<Id> _teamIdFor(String name) async {
    Id? find() => _teams
        .where((t) => t.name.toLowerCase() == name.toLowerCase())
        .firstOrNull
        ?.id;
    final existing = find();
    if (existing != null) return existing;
    try {
      final team = await client.createTeam(
        contestId,
        CreateTeamRequest(id: Id.create(), name: name),
      );
      _teams = [..._teams, team];
      return team.id;
    } on ApiHttpError catch (error) {
      if (error.statusCode != 409) rethrow;
      // Someone created it meanwhile.
      _teams = await client.teams(contestId);
      final created = find();
      if (created == null) rethrow;
      return created;
    }
  }

  /// Reads row [id] again and drops its unsaved edits (the row's Refresh).
  Future<void> refreshRow(String id) async {
    _drafts.remove(id);
    _states.remove(id);
    final name = _savedRow(id)?.name ?? 'The participant';
    await reload();
    message = '$name refreshed. Their unsaved changes were discarded.';
    notifyListeners();
  }

  // Adding and removing.

  /// Adds [profile] to the contest as [role] (Pilot when null). Repeating a
  /// failed add is safe: it reuses the same request id.
  Future<bool> add(ParticipantProfile profile, {Role? role}) async {
    if (!canEdit) return false;
    final id = _addIds.putIfAbsent(profile.id, Id.create);
    final late = drawn && (role == null || role.type == RoleType.pilot);
    try {
      final participation = await client.addParticipation(
        contestId,
        AddParticipationRequest(
          id: id,
          participantProfileId: profile.id,
          roleId: role?.id,
        ),
      );
      _addIds.remove(profile.id);
      failedAdd = null;
      failedAddRole = null;
      addFailure = null;
      addNeedsRoom = false;
      await _read();
      final rowId = participation.id.value;
      _states[rowId] = RowState(RowOutcome.added, late: late);
      highlightId = rowId;
      query = '';
      final name = '${profile.firstName} ${profile.lastName}';
      if (late) _toPlace.add(rowId);
      message = '$name added to the contest.';
    } on Object catch (error) {
      failedAdd = profile;
      failedAddRole = role;
      addFailure = apiErrorTextOf(error);
      addNeedsRoom =
          error is ApiHttpError && error.error?.code == 'no_room_in_round';
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  /// The selected rows that can go (none has flights).
  bool get selectionHasFlights =>
      rows.any((r) => selection.contains(r.rowId) && hasFlights(r));

  /// Removes the selected people one by one; the server may refuse some.
  Future<RemoveResult> removeSelected() =>
      removeParticipants(Set.of(selection));

  /// Removes explicit targets without changing the selection before confirmation.
  Future<RemoveResult> removeParticipants(Set<String> rowIds) async {
    final targets = [
      for (final r in rows)
        if (rowIds.contains(r.rowId)) r,
    ];
    final removed = <String>[];
    final left = <String>[];
    final refused = <({String name, String reason})>[];
    for (final row in targets) {
      try {
        final result = await client.removeParticipation(contestId, row.id);
        removed.add(row.name);
        if (result.matrixRowsRemoved > 0) left.add(row.name);
        _drafts.remove(row.rowId);
      } on Object catch (error) {
        refused.add((name: row.name, reason: apiErrorTextOf(error)));
      }
    }
    selection.removeAll(targets.map((row) => row.rowId));
    final result = RemoveResult(removed: removed, refused: refused);
    lastRemoval = result;
    leftTheDraw = [...leftTheDraw, ...left];
    await reload();
    if (removed.isNotEmpty) {
      message = '${_andList(removed)} removed from the contest.';
    }
    notifyListeners();
    return result;
  }

  /// The pilots to put in the rounds now, in list order; asking again returns
  /// none until someone else joins.
  List<StoredParticipant> takePendingPlacements() {
    final pending = [
      for (final row in _saved)
        if (_toPlace.contains(row.rowId) && rules.isScoring(row)) row,
    ];
    _toPlace.clear();
    return pending;
  }

  /// Puts [row] in the last group that can take them in every round, with a
  /// zero in rounds already fully scored.
  Future<void> placeInRounds(StoredParticipant row) async {
    try {
      final result = await client.placeInAllRounds(contestId, row.id);
      lastPlacement = PlacementReport(name: row.name, result: result);
      final warning = result.recalculationWarning;
      if (warning != null) recalculationWarning = warning;
    } on Object catch (error) {
      message =
          '${row.name} is in the contest but not in the rounds yet: '
          '${apiErrorTextOf(error)} Try Place in all rounds again, which is '
          'safe to repeat, or place them from the Matrix page.';
    }
    await reload();
    notifyListeners();
  }

  void dismissPlacement() {
    lastPlacement = null;
    notifyListeners();
  }

  void dismissLeftTheDraw() {
    leftTheDraw = const [];
    notifyListeners();
  }

  void dismissRemoval() {
    lastRemoval = null;
    notifyListeners();
  }

  static String andList(List<String> items) => _andList(items);

  static String _andList(List<String> items) {
    if (items.length < 2) return items.join();
    return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
  }
}

/// The server's words for [error].
String apiErrorTextOf(Object error) => ApiFailure.of(error).message;
