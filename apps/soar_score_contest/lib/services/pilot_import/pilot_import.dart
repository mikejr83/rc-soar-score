import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:soar_score_api/soar_score_api.dart' show ApiClient;
import 'package:soar_score_core/soar_score_core.dart';

/// A refused or unreadable pilot import, in a sentence for the director.
class PilotImportFailure implements Exception {
  const PilotImportFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Where the director's participants are read and saved for a GliderScore
/// pilot import. The native build has it; the web build holds no local
/// participants and has none.
abstract class PilotImportStore {
  /// The store of this build, or `null` when it has none. A test swaps in
  /// its own.
  static PilotImportStore? current;

  /// The participants the director has now.
  Future<List<ParticipantProfile>> existing();

  /// Stores the chosen pilots in one transaction. [reviewedRevisions] holds
  /// the revision of every participant the review saw. Throws a
  /// [StaleRevisionError] when a chosen participant changed since the review,
  /// and a [PilotImportReviewChangedError] when any participant was added,
  /// removed or changed.
  Future<PilotImportOutcome> apply(
    List<PilotImportSelection> selections, {
    required Map<Id, int> reviewedRevisions,
  });
}

/// The system file dialog the import uses. A journey cannot drive it, so it
/// swaps in a recorder.
class GliderScoreFiles {
  const GliderScoreFiles({required this.choose, this.read});

  /// The chooser; answers the path of the `.mdb`, or `null` when the director
  /// cancelled.
  final Future<String?> Function() choose;

  /// Reads the `Pilots` table of the file at the path. `null` means through
  /// the API (the GliderScore reader of this installation); a journey sets it
  /// to answer from a fixture, since it has no `.mdb` to read.
  final Future<GliderScoreImportResult> Function(ApiClient client, String path)?
  read;

  static GliderScoreFiles current = const GliderScoreFiles(
    choose: _systemChoose,
  );
}

Future<String?> _systemChoose() async {
  final file = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(label: 'GliderScore database', extensions: ['mdb']),
    ],
  );
  return file?.path;
}

/// What reading a file found: the pilots, and how each relates to the
/// participants the director already has.
class PilotImportReview {
  const PilotImportReview({
    required this.draft,
    required this.matches,
    required this.existing,
  });

  final PilotImportDraft draft;
  final List<PilotMatch> matches;

  /// The participants the matches refer to.
  final List<ParticipantProfile> existing;

  ParticipantProfile? profile(Id id) {
    for (final p in existing) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// Where the import is.
enum PilotImportStep {
  /// Waiting for the first file.
  idle,

  /// Reading the file.
  reading,

  /// Showing what was found.
  review,

  /// Saving.
  applying,

  /// Saved.
  done,

  /// Reading or saving failed; see [PilotImportController.error].
  failed,
}

/// The state of one pilot import: choose a file, read it, review, save.
///
/// Holds no widgets, so it is tested on its own. [readFile] reads the pilots
/// of a `.mdb` through the API.
class PilotImportController extends ChangeNotifier {
  PilotImportController({
    required this.store,
    required this.readFile,
    GliderScoreFiles? files,
    this.pilotFilter,
  }) : _files = files ?? GliderScoreFiles.current;

  /// When set, only the pilots it accepts are reviewed. The competition
  /// import uses it to review just the pilots of the competitions it chose.
  final bool Function(PilotDraft pilot)? pilotFilter;

  final PilotImportStore store;
  final Future<GliderScoreImportResult> Function(String path) readFile;
  final GliderScoreFiles _files;

  static const _mapper = GliderScorePilotMapper();
  static const _matcher = PilotImportMatcher();

  PilotImportStep _step = PilotImportStep.idle;
  PilotImportStep get step => _step;

  String? _fileName;
  String? get fileName => _fileName;

  GliderScoreImportResult? _result;
  PilotImportReview? _review;
  PilotImportReview? get review => _review;

  List<PilotImportSelection> _selections = const [];
  List<PilotImportSelection> get selections => _selections;

  PilotImportOutcome? _outcome;
  PilotImportOutcome? get outcome => _outcome;

  Object? _error;

  /// What went wrong when [step] is [PilotImportStep.failed].
  Object? get error => _error;

  /// True when the failure is that a participant changed during the review.
  bool get changedDuringReview =>
      _error is StaleRevisionError || _error is PilotImportReviewChangedError;

  /// True when nothing was read yet, so a failure can be retried by choosing
  /// a file again.
  bool get canChooseAgain => _result == null;

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
    if (path == null) {
      return false;
    }
    _fileName = path.split(RegExp(r'[\\/]')).last;
    await _read(path);
    return true;
  }

  Future<void> _read(String path) async {
    _set(PilotImportStep.reading);
    try {
      _result = await readFile(path);
      await _prepare();
    } on Object catch (e) {
      _fail(e);
    }
  }

  /// Reviews the pilots of a [result] already read, as if [fileName] had been
  /// chosen. The competition import reads the file once for both.
  Future<void> loadResult(
    GliderScoreImportResult result, {
    String? fileName,
  }) async {
    _result = result;
    _fileName = fileName ?? result.sourceDbFile;
    _set(PilotImportStep.reading);
    try {
      await _prepare();
    } on Object catch (e) {
      _fail(e);
    }
  }

  Future<void> _prepare() async {
    final result = _result!;
    final draft = _mapper.map(result);
    final existing = await store.existing();
    final filter = pilotFilter;
    final matches = _matcher.match(
      filter == null ? draft.pilots : draft.pilots.where(filter).toList(),
      existing,
    );
    _review = PilotImportReview(
      draft: draft,
      matches: matches,
      existing: existing,
    );
    _selections = [
      for (final match in matches) PilotImportSelection.defaultFor(match),
    ];
    _set(PilotImportStep.review);
  }

  /// Reads the participants again and rebuilds the review from the same
  /// file, after a participant changed under it. With no file read yet (the
  /// chooser failed) it asks for a file again.
  Future<void> reviewAgain() async {
    if (_result == null) {
      await chooseAndRead();
      return;
    }
    _set(PilotImportStep.reading);
    try {
      await _prepare();
    } on Object catch (e) {
      _fail(e);
    }
  }

  /// Sets what happens to the pilot at [index] of [PilotImportReview.matches].
  /// For an update, [target] names the participant (it defaults to the only
  /// candidate).
  void choose(int index, PilotImportChoice choice, {Id? target}) {
    final old = _selections[index];
    _selections = [..._selections]
      ..[index] = PilotImportSelection(
        match: old.match,
        choice: choice,
        targetProfileId:
            target ??
            (choice == PilotImportChoice.update &&
                    old.match.candidateIds.length == 1
                ? old.match.candidateIds.single
                : null),
        newProfileId: old.newProfileId,
      );
    notifyListeners();
  }

  /// How many pilots will be added, updated (with something to change) and
  /// left out if the import is applied now.
  ({int added, int updated, int unchanged, int skipped}) get plan {
    var added = 0, updated = 0, unchanged = 0, skipped = 0;
    for (final s in _selections) {
      switch (s.choice) {
        case PilotImportChoice.add:
          added++;
        case PilotImportChoice.update:
          if (s.match.isUnchanged) {
            unchanged++;
          } else {
            updated++;
          }
        case PilotImportChoice.skip:
          skipped++;
      }
    }
    return (
      added: added,
      updated: updated,
      unchanged: unchanged,
      skipped: skipped,
    );
  }

  /// Saves the review's choices.
  Future<void> apply() async {
    _set(PilotImportStep.applying);
    try {
      _outcome = await store.apply(
        _selections,
        reviewedRevisions: {
          for (final p in _review!.existing) p.id: p.revision,
        },
      );
      _set(PilotImportStep.done);
    } on Object catch (e) {
      _fail(e);
    }
  }

  void _fail(Object error) {
    _error = error;
    _set(PilotImportStep.failed);
  }

  void _set(PilotImportStep step) {
    _step = step;
    if (step != PilotImportStep.failed) {
      _error = null;
    }
    notifyListeners();
  }
}
