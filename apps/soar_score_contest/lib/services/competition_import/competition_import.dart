import 'package:flutter/foundation.dart';
import 'package:soar_score_api/soar_score_api.dart' show ApiClient;
import 'package:soar_score_core/soar_score_core.dart';

import '../pilot_import/pilot_import.dart';

/// Where imported competitions are written. The native build has it; the web
/// build holds no local data and has none.
///
/// It is also the [PilotImportStore] of the pilots the chosen competitions
/// use, so one review serves both.
abstract class CompetitionImportStore implements PilotImportStore {
  /// The store of this build, or `null` when it has none. A test swaps in
  /// its own.
  static CompetitionImportStore? current;

  /// A hash of the file at [path] and its name, the same for every
  /// competition of one run (ADR 0006).
  Future<String> fingerprint(String path);

  /// Stamps the profiles the run created or updated.
  Future<void> stampProfiles({
    required Id operationId,
    required String fingerprint,
    required List<ProfileStampEntry> entries,
  });

  /// What restoring the competition with [identity] would meet: the contest
  /// an earlier import made of it, if any (ADR 0006, amendment 2).
  Future<RestoreTarget> restoreTarget(RestoreIdentity identity);

  /// Restores one competition: its contest, participants, draw, scores,
  /// re-flights, retirements and final state, in one transaction. Never throws
  /// for a problem of the competition itself; the result says what happened.
  Future<RestoreImportResult> importRestore({
    required RestorePlan plan,
    required Map<int, Id> profileIds,
    required Id operationId,
    required String fingerprint,
    required bool completed,
    required bool confirmedReplace,
    Id? updateContestId,
  });

  /// What the import left in [contestId], or `null` when the contest was not
  /// imported.
  Future<ImportedContestNote?> noteFor(Id contestId);
}

/// A file read and mapped: one restore plan per competition.
class MappedGliderScoreFile {
  const MappedGliderScoreFile(this.plans);

  final List<RestorePlan> plans;
}

/// Maps every competition of [result]. Pure and made of plain data, so it can
/// run on a background isolate.
MappedGliderScoreFile mapGliderScoreFile(GliderScoreImportResult result) =>
    MappedGliderScoreFile(const GliderScoreRestoreMapper().map(result));

/// Maps [result] without blocking the UI isolate on a large file.
Future<MappedGliderScoreFile> mapGliderScoreFileInBackground(
  GliderScoreImportResult result,
) => compute(mapGliderScoreFile, result);

/// Where the competition import is.
enum CompetitionImportStep {
  /// Waiting for the first file.
  idle,

  /// Reading and mapping the file, off the UI thread.
  reading,

  /// Choosing which competitions to import.
  competitions,

  /// Reviewing the pilots of the chosen competitions.
  pilots,

  /// Looking over what will happen.
  confirm,

  /// Writing.
  applying,

  /// Finished; see [CompetitionImportController.results].
  done,

  /// Reading or the pilot step failed; see [CompetitionImportController.error].
  failed,
}

/// The state of one competition import: choose a file, read it, choose
/// competitions, review pilots, confirm, restore.
///
/// Holds no widgets, so it is tested on its own. The pilot review is the
/// Phase A [PilotImportController], limited to the pilots the chosen
/// competitions use.
class CompetitionImportController extends ChangeNotifier {
  CompetitionImportController({
    required this.store,
    required this.readFile,
    GliderScoreFiles? files,
    Id Function()? newId,
    Future<MappedGliderScoreFile> Function(GliderScoreImportResult)? mapFile,
  }) : _files = files ?? GliderScoreFiles.current,
       _newId = newId ?? Id.create,
       _mapFile = mapFile ?? mapGliderScoreFileInBackground {
    pilots = PilotImportController(
      store: store,
      readFile: (_) async => throw StateError('the file is read once'),
      files: _files,
      pilotFilter: (pilot) => _usedPilots.contains(pilot.sourcePilotNo),
    );
    // The pilots step shows the inner controller's choices, so its changes
    // must redraw the dialog that listens to this one.
    pilots.addListener(notifyListeners);
  }

  /// The tables a competition import reads, all of which the mappers use.
  ///
  /// `Scores` holds the drawn and the scored flights.
  static const tables = [
    'Pilots',
    'Comps',
    'CompPilots',
    'Dur',
    'Scores',
    'DBParams',
  ];

  /// The tables without the optional `DBParams`, for a file that lacks it.
  static const tablesWithoutDbParams = [
    'Pilots',
    'Comps',
    'CompPilots',
    'Dur',
    'Scores',
  ];

  /// Reads the tables the import needs of the file at a path.
  static Future<GliderScoreImportResult> read(
    ApiClient client,
    String path,
  ) async {
    final custom = GliderScoreFiles.current.read;
    if (custom != null) return custom(client, path);
    try {
      return await client.importGliderScore(path, tables: tables);
    } on Object catch (error) {
      if ('$error'.contains('DBParams')) {
        return client.importGliderScore(path, tables: tablesWithoutDbParams);
      }
      rethrow;
    }
  }

  final CompetitionImportStore store;
  final Future<GliderScoreImportResult> Function(String path) readFile;
  final GliderScoreFiles _files;
  final Id Function() _newId;
  final Future<MappedGliderScoreFile> Function(GliderScoreImportResult)
  _mapFile;

  /// The review of the pilots the chosen competitions use.
  late final PilotImportController pilots;

  CompetitionImportStep _step = CompetitionImportStep.idle;
  CompetitionImportStep get step => _step;

  String? _fileName;
  String? get fileName => _fileName;

  GliderScoreImportResult? _result;
  List<RestorePlan> _plans = const [];
  String? _fingerprint;

  /// What each importable competition would meet in this installation.
  Map<int, RestoreTarget> _targets = const {};

  final Set<int> _chosen = {};
  Set<int> get chosen => Set.unmodifiable(_chosen);

  final Map<int, bool> _completed = {};

  /// Competitions without a `CompID` that the director said are the contest
  /// of an earlier import with the same number.
  final Set<int> _sameAs = {};

  bool _replaceConfirmed = false;

  Set<int> get _usedPilots => {
    for (final plan in chosenPlans)
      for (final p in plan.contest.participants) p.sourcePilotNo,
  };

  List<RestoreImportResult> _results = const [];

  /// What happened to each chosen competition, in `CompNo` order.
  List<RestoreImportResult> get results => _results;

  Object? _error;

  /// What went wrong when [step] is [CompetitionImportStep.failed].
  Object? get error => _error;

  /// True when the failure is that a participant changed during the review.
  bool get changedDuringReview => pilots.changedDuringReview;

  /// True when the failure came after the file was read, so the review can
  /// be rebuilt without choosing the file again.
  bool get canReviewAgain => _result != null;

  /// Asks for a file and reads it. Returns false when the director cancelled
  /// the chooser.
  Future<bool> chooseAndRead() async {
    final String? path;
    try {
      path = await _files.choose();
    } on Object catch (e) {
      _fail(e);
      return true;
    }
    if (path == null) return false;
    _fileName = path.split(RegExp(r'[\\/]')).last;
    _set(CompetitionImportStep.reading);
    try {
      final result = await readFile(path);
      final fingerprint = await store.fingerprint(path);
      // A director who cancelled while the file was read wants none of it.
      if (_step != CompetitionImportStep.reading) return true;
      final mapped = await _mapFile(result);
      if (_step != CompetitionImportStep.reading) return true;
      final targets = await _findTargets(mapped.plans);
      if (_step != CompetitionImportStep.reading) return true;
      _result = result;
      _fingerprint = fingerprint;
      _plans = mapped.plans;
      _targets = targets;
      _chosen.clear();
      _completed.clear();
      _sameAs.clear();
      _replaceConfirmed = false;
      _set(CompetitionImportStep.competitions);
    } on Object catch (e) {
      if (_step == CompetitionImportStep.reading) _fail(e);
    }
    return true;
  }

  /// What an earlier import of each importable competition left. A
  /// competition whose lookup fails is treated as new.
  Future<Map<int, RestoreTarget>> _findTargets(List<RestorePlan> plans) async {
    final targets = <int, RestoreTarget>{};
    for (final plan in plans) {
      if (!plan.isImportable) continue;
      try {
        final target = await store.restoreTarget(plan.identity);
        if (target.exists) targets[plan.sourceCompNo] = target;
      } on Object {
        continue;
      }
    }
    return targets;
  }

  /// Drops the read in progress. A result that arrives later is ignored.
  void cancelReading() {
    if (_step == CompetitionImportStep.reading) {
      _set(CompetitionImportStep.idle);
    }
  }

  /// The competitions of the file as the wizard lists them: the most recent
  /// start first, undated ones last. Ties go by name (A to Z), then `CompNo`.
  List<RestorePlan> get listed {
    final all = [..._plans];
    all.sort((a, b) {
      final x = a.contest.startDate;
      final y = b.contest.startDate;
      if (x != y) {
        if (x == null) return 1;
        if (y == null) return -1;
        return y.compareTo(x);
      }
      final byName = (a.contest.name ?? a.contest.sourceClass)
          .toLowerCase()
          .compareTo((b.contest.name ?? b.contest.sourceClass).toLowerCase());
      return byName != 0 ? byName : a.sourceCompNo.compareTo(b.sourceCompNo);
    });
    return all;
  }

  RestorePlan? planOf(int compNo) {
    for (final plan in _plans) {
      if (plan.sourceCompNo == compNo) return plan;
    }
    return null;
  }

  /// What the earlier import of [compNo] left, or null for a new competition.
  RestoreTarget? targetOf(int compNo) => _targets[compNo];

  /// The contest [compNo] replaces, or null when it makes a new one.
  RestoreTarget? replacedBy(int compNo) {
    final target = _targets[compNo];
    if (target == null) return null;
    return switch (target.kind) {
      RestoreTargetKind.same => target,
      RestoreTargetKind.numberMatch => _sameAs.contains(compNo) ? target : null,
      RestoreTargetKind.none => null,
    };
  }

  /// A [RestoreRefusal] code when the competition cannot be restored over the
  /// contest it would replace, else null.
  String? refusalOf(int compNo) {
    final target = replacedBy(compNo);
    if (target == null) return null;
    if (target.published) return RestoreRefusal.resultsPublished;
    if (target.synced) return RestoreRefusal.contestSynced;
    return null;
  }

  /// The competitions of the file that can be chosen.
  List<RestorePlan> get importable => [
    for (final plan in _plans)
      if (plan.isImportable && refusalOf(plan.sourceCompNo) == null) plan,
  ];

  /// Chooses or drops competition [compNo]. Only an importable one can be
  /// chosen.
  void toggle(int compNo) {
    if (!importable.any((p) => p.sourceCompNo == compNo)) return;
    if (!_chosen.remove(compNo)) {
      _chosen.add(compNo);
      _completed.putIfAbsent(compNo, () => planOf(compNo)!.completedByDefault);
    }
    _replaceConfirmed = false;
    notifyListeners();
  }

  /// Chooses every importable competition, or none.
  void setAll(bool chosen) {
    _chosen.clear();
    if (chosen) {
      for (final plan in importable) {
        _chosen.add(plan.sourceCompNo);
        _completed.putIfAbsent(
          plan.sourceCompNo,
          () => plan.completedByDefault,
        );
      }
    }
    _replaceConfirmed = false;
    notifyListeners();
  }

  /// Whether [compNo] ends Completed: the director's checkbox, preselected
  /// from the file.
  bool completed(int compNo) =>
      _completed[compNo] ?? planOf(compNo)?.completedByDefault ?? false;

  void setCompleted(int compNo, bool value) {
    if (completed(compNo) == value && _completed.containsKey(compNo)) return;
    _completed[compNo] = value;
    notifyListeners();
  }

  /// Whether the director said [compNo] is the competition of the earlier
  /// contest with the same number.
  bool isSameAs(int compNo) => _sameAs.contains(compNo);

  void setSameAs(int compNo, bool value) {
    if (value ? !_sameAs.add(compNo) : !_sameAs.remove(compNo)) return;
    if (!importable.any((p) => p.sourceCompNo == compNo)) {
      _chosen.remove(compNo);
    }
    _replaceConfirmed = false;
    notifyListeners();
  }

  /// The chosen competitions, in `CompNo` order.
  List<RestorePlan> get chosenPlans => [
    for (final plan in importable)
      if (_chosen.contains(plan.sourceCompNo)) plan,
  ];

  /// Competitions chosen so far.
  int get chosenTotal => _chosen.length;

  /// What the director is asked to confirm: contests replaced that were
  /// changed in Soar Score after the import.
  List<RestoreTarget> get changedTargets => [
    for (final plan in chosenPlans)
      if (replacedBy(plan.sourceCompNo) case final target?)
        if (target.changes.any &&
            !target.isUnchanged(plan.contentHash, completed(plan.sourceCompNo)))
          target,
  ];

  /// Whether the director must tick "replace" before importing.
  bool get needsReplaceConfirmation => changedTargets.isNotEmpty;

  bool get replaceConfirmed => _replaceConfirmed;

  void setReplaceConfirmed(bool value) {
    _replaceConfirmed = value;
    notifyListeners();
  }

  /// From the competitions to the pilots of the chosen ones.
  Future<void> continueToPilots() async {
    if (_chosen.isEmpty) return;
    _set(CompetitionImportStep.reading);
    await pilots.loadResult(_result!, fileName: _fileName);
    if (pilots.step == PilotImportStep.review) {
      _set(CompetitionImportStep.pilots);
    } else {
      _fail(pilots.error ?? StateError('the pilot review did not open'));
    }
  }

  /// Back from the pilots to the competitions.
  void backToCompetitions() => _set(CompetitionImportStep.competitions);

  /// From the pilots to the summary.
  void continueToConfirm() => _set(CompetitionImportStep.confirm);

  /// Back from the summary to the pilots.
  void backToPilots() => _set(CompetitionImportStep.pilots);

  /// Reads the participants again and rebuilds the pilot review after a
  /// participant changed under it.
  Future<void> reviewAgain() async {
    if (_result == null) {
      await chooseAndRead();
      return;
    }
    await continueToPilots();
  }

  /// What the import will do.
  ({
    int created,
    int replaced,
    int unchanged,
    int flights,
    int completed,
    int newPilots,
    int updatedPilots,
    int skippedPilots,
  })
  get summary {
    var created = 0;
    var replaced = 0;
    var unchanged = 0;
    var flights = 0;
    var closed = 0;
    for (final plan in chosenPlans) {
      final target = replacedBy(plan.sourceCompNo);
      final done = completed(plan.sourceCompNo);
      if (target == null) {
        created++;
      } else if (target.isUnchanged(plan.contentHash, done)) {
        unchanged++;
      } else {
        replaced++;
      }
      flights += plan.flights.length;
      if (done && plan.hasScoredFlights) closed++;
    }
    final p = pilots.plan;
    return (
      created: created,
      replaced: replaced,
      unchanged: unchanged,
      flights: flights,
      completed: closed,
      newPilots: _chosen.isEmpty ? 0 : p.added,
      updatedPilots: _chosen.isEmpty ? 0 : p.updated,
      skippedPilots: _chosen.isEmpty ? 0 : p.skipped,
    );
  }

  /// Saves the pilots, stamps them, then restores each chosen competition.
  /// One competition failing does not undo the others.
  Future<void> apply() async {
    _set(CompetitionImportStep.applying);
    final operation = _newId();
    try {
      final results = await _applyContests(operation);
      if (results == null) return;
      _results = results;
      _set(CompetitionImportStep.done);
    } on Object catch (e) {
      _fail(e);
    }
  }

  /// Saves and stamps the pilots, then restores the chosen competitions.
  /// Null when the pilots were not saved (the step has failed).
  Future<List<RestoreImportResult>?> _applyContests(Id operation) async {
    await pilots.apply();
    if (pilots.step != PilotImportStep.done) {
      _fail(pilots.error ?? StateError('the pilots were not saved'));
      return null;
    }
    final profileIds = <int, Id>{};
    final entries = <ProfileStampEntry>[];
    final outcome = pilots.outcome!;
    final created = {for (final p in outcome.added) p.id};
    final updated = {for (final p in outcome.updated) p.id};
    for (final selection in pilots.selections) {
      final number = selection.match.draft.sourcePilotNo;
      if (number == null) continue;
      final Id? id = switch (selection.choice) {
        PilotImportChoice.add => selection.newProfileId,
        PilotImportChoice.update =>
          selection.targetProfileId ??
              (selection.match.candidateIds.length == 1
                  ? selection.match.candidateIds.single
                  : null),
        PilotImportChoice.skip => null,
      };
      if (id == null) continue;
      profileIds[number] = id;
      if (created.contains(id) || updated.contains(id)) {
        entries.add(
          ProfileStampEntry(
            sourcePilotNo: number,
            profileId: id,
            created: created.contains(id),
          ),
        );
      }
    }
    await store.stampProfiles(
      operationId: operation,
      fingerprint: _fingerprint!,
      entries: entries,
    );
    final results = <RestoreImportResult>[];
    for (final plan in chosenPlans) {
      final replaced = replacedBy(plan.sourceCompNo);
      try {
        results.add(
          await store.importRestore(
            plan: plan,
            profileIds: profileIds,
            operationId: operation,
            fingerprint: _fingerprint!,
            completed: completed(plan.sourceCompNo),
            confirmedReplace: _replaceConfirmed,
            updateContestId: replaced?.kind == RestoreTargetKind.numberMatch
                ? replaced!.contestId
                : null,
          ),
        );
      } on Object catch (e) {
        results.add(
          CompetitionRestoreFailed(
            plan.sourceCompNo,
            RestoreFailure.failed,
            detail: '$e',
          ),
        );
      }
    }
    return results;
  }

  /// True when at least one contest was written.
  bool get anyImported => _results.any((r) => r is CompetitionRestored);

  /// The contests written, for the caller to show.
  List<Id> get importedContestIds => [
    for (final r in _results)
      if (r is CompetitionRestored) r.contestId,
  ];

  void _fail(Object error) {
    _error = error;
    _set(CompetitionImportStep.failed);
  }

  void _set(CompetitionImportStep step) {
    _step = step;
    if (step != CompetitionImportStep.failed) _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    pilots.removeListener(notifyListeners);
    pilots.dispose();
    super.dispose();
  }
}
