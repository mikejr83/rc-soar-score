import 'package:flutter/foundation.dart';

import 'package:soar_score_core/soar_score_core.dart';

import 'contest_creator.dart';
import 'contest_draft.dart';
import 'draw_settings.dart';

/// Writes a draft somewhere; throws when it cannot.
typedef DraftWriter = Future<void> Function(ContestDraft draft);

/// Holds the user's single New Contest draft for the life of the app.
///
/// A user has one draft at a time. Leaving the wizard keeps it until the app
/// is closed, and opening the wizard again resumes it. Every change is saved
/// as it happens; a failed save keeps the values in memory and reports
/// [saveFailed] so the wizard can offer a retry.
class ContestDraftStore extends ChangeNotifier {
  ContestDraftStore({this.writer, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Where the draft is saved; `null` keeps it in memory only.
  final DraftWriter? writer;
  final DateTime Function() _clock;

  ContestDraft _draft = const ContestDraft();
  DateTime? _savedAt;
  bool _saveFailed = false;
  CreationIds? _creationIds;

  /// The draw settings chosen for contests created in this session, by
  /// contest id. Groups per round, back-to-back flights and planned rounds
  /// are set when the matrix is drawn, so they wait here to prefill the
  /// draw.
  final Map<Id, DrawSettings> drawSuggestions = {};

  /// The ids for creating the contest from this draft, kept across retries
  /// so a repeated attempt can't create a second contest. Once the draft has
  /// changed since an earlier attempt, new ids are made, because the server
  /// refuses an existing contest id with different content.
  CreationIds creationIdsFor(ContestDraft draft) {
    final signature = ContestCreator.signature(draft);
    final ids = _creationIds;
    if (ids != null && ids.signature == signature) {
      return ids;
    }
    return _creationIds = CreationIds(signature);
  }

  /// The current draft (saved or not).
  ContestDraft get draft => _draft;

  /// When the draft was last saved, or `null` before the first save.
  DateTime? get savedAt => _savedAt;

  /// Whether the latest save failed.
  bool get saveFailed => _saveFailed;

  /// Replaces the draft and saves it.
  Future<void> update(ContestDraft draft) {
    _draft = draft;
    notifyListeners();
    return _save();
  }

  /// Tries the failed save again.
  Future<void> retry() => _save();

  /// Stops reporting the failed save; the values stay on screen.
  void dismissFailure() {
    if (_saveFailed) {
      _saveFailed = false;
      notifyListeners();
    }
  }

  /// Drops the draft, for example once the contest is created.
  void discard() {
    _draft = const ContestDraft();
    _savedAt = null;
    _saveFailed = false;
    _creationIds = null;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      await writer?.call(_draft);
      _savedAt = _clock();
      _saveFailed = false;
    } on Object {
      _saveFailed = true;
    }
    notifyListeners();
  }
}
