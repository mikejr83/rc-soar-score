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

  /// Writes one competition as a contest. Never throws for a problem of the
  /// competition itself; the result says what happened.
  Future<CompetitionImportResult> importCompetition({
    required ContestImportDraft draft,
    required Map<int, Id> profileIds,
    required Id operationId,
    required String fingerprint,
  });

  /// What adding the draw of competition [compNo] needs to know about the
  /// contest an earlier run made from it (ADR 0006 amendment).
  Future<DrawImportTarget> drawTarget({
    required int compNo,
    required String fingerprint,
  });

  /// Adds the draw of one competition to the contest [contestId] made from
  /// it. Never throws for a problem of the competition itself; the result says
  /// what happened.
  Future<DrawImportResult> importDraw({
    required DrawImportDraft draft,
    required Id contestId,
    required Id operationId,
    required String fingerprint,
  });

  /// What the import left out of [contestId], or `null` when the contest was
  /// not imported.
  Future<ImportedContestNote?> noteFor(Id contestId);
}

/// The draw of a competition whose contest an earlier run made, and what
/// adding it would do. Refused offers say why; the rest can be chosen.
class DrawOffer {
  const DrawOffer({required this.target, required this.draft});

  final DrawImportTarget target;
  final DrawImportDraft draft;

  bool get canAdd => draft.isImportable && target.contestId != null;
}

/// Where the competition import is.
enum CompetitionImportStep {
  /// Waiting for the first file.
  idle,

  /// Reading the file.
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
/// competitions, review pilots, confirm, write.
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
  }) : _files = files ?? GliderScoreFiles.current,
       _newId = newId ?? Id.create {
    pilots = PilotImportController(
      store: store,
      readFile: (_) async => throw StateError('the file is read once'),
      files: _files,
      pilotFilter: (pilot) => _usedPilots.contains(pilot.sourcePilotNo),
    );
  }

  /// The tables a competition import reads, all of which the mappers use.
  ///
  /// `Scores` holds the drawn flights; it is read for the draw a competition
  /// imported before can still receive.
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

  /// The review of the pilots the chosen competitions use.
  late final PilotImportController pilots;

  static const _mapper = GliderScoreContestMapper();
  static const _drawMapper = GliderScoreDrawMapper();

  CompetitionImportStep _step = CompetitionImportStep.idle;
  CompetitionImportStep get step => _step;

  String? _fileName;
  String? get fileName => _fileName;

  GliderScoreImportResult? _result;
  CompetitionImportDraft? _draft;
  CompetitionImportDraft? get draft => _draft;

  String? _fingerprint;

  final Set<int> _chosen = {};
  Set<int> get chosen => Set.unmodifiable(_chosen);

  Set<int> get _usedPilots => {
    for (final c in _draft?.contests ?? const <ContestImportDraft>[])
      if (_chosen.contains(c.sourceCompNo) && c.isImportable)
        for (final p in c.participants) p.sourcePilotNo,
  };

  /// The draws that can be added, by competition number: every competition
  /// of the file with a contest from an earlier run.
  Map<int, DrawOffer> _offers = const {};
  Map<int, DrawOffer> get offers => _offers;

  final Set<int> _chosenDraws = {};
  Set<int> get chosenDraws => Set.unmodifiable(_chosenDraws);

  List<DrawImportResult> _drawResults = const [];

  /// What happened to each chosen draw, in `CompNo` order.
  List<DrawImportResult> get drawResults => _drawResults;

  List<CompetitionImportResult> _results = const [];

  /// What happened to each chosen competition, in `CompNo` order.
  List<CompetitionImportResult> get results => _results;

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
      _result = result;
      _fingerprint = fingerprint;
      _draft = _mapper.map(result);
      _chosen.clear();
      _chosenDraws.clear();
      _offers = await _findOffers(result, fingerprint);
      if (_step != CompetitionImportStep.reading) return true;
      _set(CompetitionImportStep.competitions);
    } on Object catch (e) {
      if (_step == CompetitionImportStep.reading) _fail(e);
    }
    return true;
  }

  /// The draws of competitions that already have a contest. A competition
  /// whose lookup or mapping fails simply has no offer.
  Future<Map<int, DrawOffer>> _findOffers(
    GliderScoreImportResult result,
    String fingerprint,
  ) async {
    final offers = <int, DrawOffer>{};
    for (final c in _draft?.contests ?? const <ContestImportDraft>[]) {
      if (!c.isImportable) continue;
      try {
        final target = await store.drawTarget(
          compNo: c.sourceCompNo,
          fingerprint: fingerprint,
        );
        if (!target.stamped) continue;
        offers[c.sourceCompNo] = DrawOffer(
          target: target,
          draft: _drawMapper.mapCompetition(result, target),
        );
      } on Object {
        continue;
      }
    }
    return offers;
  }

  /// Drops the read in progress. A result that arrives later is ignored.
  void cancelReading() {
    if (_step == CompetitionImportStep.reading) {
      _set(CompetitionImportStep.idle);
    }
  }

  /// The competitions of the file as the wizard lists them: the most recent
  /// start first, undated ones last. Ties go by name (A to Z), then `CompNo`.
  List<ContestImportDraft> get listed {
    final all = [...?_draft?.contests];
    all.sort((a, b) {
      final x = a.startDate;
      final y = b.startDate;
      if (x != y) {
        if (x == null) return 1;
        if (y == null) return -1;
        return y.compareTo(x);
      }
      final byName = (a.name ?? a.sourceClass).toLowerCase().compareTo(
        (b.name ?? b.sourceClass).toLowerCase(),
      );
      return byName != 0 ? byName : a.sourceCompNo.compareTo(b.sourceCompNo);
    });
    return all;
  }

  /// The competitions of the file that can be chosen.
  List<ContestImportDraft> get importable => [
    for (final c in _draft?.contests ?? const <ContestImportDraft>[])
      if (c.isImportable) c,
  ];

  /// Chooses or drops competition [compNo]. Only an importable one can be
  /// chosen.
  void toggle(int compNo) {
    if (!importable.any((c) => c.sourceCompNo == compNo)) return;
    if (!_chosen.remove(compNo)) _chosen.add(compNo);
    notifyListeners();
  }

  /// Chooses or drops adding the draw of competition [compNo]. Only an offer
  /// that can be added can be chosen.
  void toggleDraw(int compNo) {
    if (_offers[compNo]?.canAdd != true) return;
    if (!_chosenDraws.remove(compNo)) _chosenDraws.add(compNo);
    notifyListeners();
  }

  /// Contests and draws chosen so far.
  int get chosenTotal => _chosen.length + _chosenDraws.length;

  /// The chosen draws, in `CompNo` order.
  List<DrawOffer> get chosenOffers => [
    for (final no in _chosenDraws.toList()..sort()) _offers[no]!,
  ];

  /// Chooses every importable competition, or none.
  void setAll(bool chosen) {
    _chosen
      ..clear()
      ..addAll(chosen ? importable.map((c) => c.sourceCompNo) : const <int>[]);
    notifyListeners();
  }

  /// The chosen competitions, in `CompNo` order.
  List<ContestImportDraft> get chosenCompetitions => [
    for (final c in importable)
      if (_chosen.contains(c.sourceCompNo)) c,
  ];

  /// From the competitions on: to the pilots of the chosen contests, or, when
  /// only draws are chosen, straight to the summary (their participants
  /// are already in the contests).
  Future<void> continueFromCompetitions() async {
    if (_chosen.isEmpty && _chosenDraws.isNotEmpty) {
      _set(CompetitionImportStep.confirm);
      return;
    }
    await continueToPilots();
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

  /// Back from the summary to the pilots, or to the competitions when only
  /// draws were chosen.
  void backToPilots() => _set(
    _chosen.isEmpty
        ? CompetitionImportStep.competitions
        : CompetitionImportStep.pilots,
  );

  /// Reads the participants again and rebuilds the pilot review after a
  /// participant changed under it.
  Future<void> reviewAgain() async {
    if (_result == null) {
      await chooseAndRead();
      return;
    }
    await continueToPilots();
  }

  /// How many contests, new pilots and updated pilots the import will write.
  ({int contests, int newPilots, int updatedPilots, int skippedPilots})
  get plan {
    if (_chosen.isEmpty) {
      return (contests: 0, newPilots: 0, updatedPilots: 0, skippedPilots: 0);
    }
    final p = pilots.plan;
    return (
      contests: _chosen.length,
      newPilots: p.added,
      updatedPilots: p.updated,
      skippedPilots: p.skipped,
    );
  }

  /// How many draws the import will add.
  int get drawsToAdd => _chosenDraws.length;

  /// Saves the pilots, stamps them, then writes each chosen competition and
  /// adds each chosen draw. One competition failing does not undo the others.
  Future<void> apply() async {
    _set(CompetitionImportStep.applying);
    final operation = _newId();
    try {
      final results = _chosen.isEmpty
          ? <CompetitionImportResult>[]
          : await _applyContests(operation);
      if (results == null) return;
      final drawResults = <DrawImportResult>[];
      for (final offer in chosenOffers) {
        final compNo = offer.draft.sourceCompNo;
        try {
          drawResults.add(
            await store.importDraw(
              draft: offer.draft,
              contestId: offer.target.contestId!,
              operationId: operation,
              fingerprint: _fingerprint!,
            ),
          );
        } on Object catch (e) {
          drawResults.add(
            DrawImportFailed(compNo, DrawImportFailure.failed, '$e'),
          );
        }
      }
      _results = results;
      _drawResults = drawResults;
      _set(CompetitionImportStep.done);
    } on Object catch (e) {
      _fail(e);
    }
  }

  /// Saves and stamps the pilots, then writes the chosen competitions as
  /// contests. Null when the pilots were not saved (the step has failed).
  Future<List<CompetitionImportResult>?> _applyContests(Id operation) async {
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
    final results = <CompetitionImportResult>[];
    for (final competition in chosenCompetitions) {
      try {
        results.add(
          await store.importCompetition(
            draft: competition,
            profileIds: profileIds,
            operationId: operation,
            fingerprint: _fingerprint!,
          ),
        );
      } on Object catch (e) {
        results.add(
          CompetitionImportFailed(
            competition.sourceCompNo,
            CompetitionImportFailure.failed,
            '$e',
          ),
        );
      }
    }
    return results;
  }

  /// True when at least one contest was written or received a draw.
  bool get anyImported =>
      _results.any((r) => r is CompetitionImported) ||
      _drawResults.any((r) => r is DrawImported);

  /// The contests written or given a draw, for the caller to show.
  List<Id> get importedContestIds => {
    for (final r in _results)
      if (r is CompetitionImported) r.contestId,
    for (final r in _drawResults)
      if (r is DrawImported) r.contestId,
  }.toList();

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
    pilots.dispose();
    super.dispose();
  }
}
