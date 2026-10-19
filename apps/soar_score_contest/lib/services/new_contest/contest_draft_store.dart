import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:soar_score_core/soar_score_core.dart';

import 'contest_creator.dart';
import 'contest_draft.dart';
import 'draft_persistence.dart';
import 'draw_settings.dart';

/// Holds the user's single New Contest draft.
///
/// A user has one draft at a time. Leaving the wizard keeps it, and opening
/// the wizard again resumes it. Every change is saved as it happens; a failed
/// save keeps the values in memory and reports [saveFailed] so the wizard can
/// offer a retry.
///
/// With a [persistence] the draft also survives closing the app: the first
/// time the wizard opens, [restore] finds the account's stored draft and the
/// director chooses to continue it ([continueWith]) or start fresh
/// ([discard]).
class ContestDraftStore extends ChangeNotifier {
  ContestDraftStore({this.persistence, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Where the draft is kept across restarts; `null` keeps it in memory only.
  final DraftPersistence? persistence;
  final DateTime Function() _clock;

  /// The account the draft in memory belongs to, set by [restore]; saves go
  /// to this account even if the signed-in account changes meanwhile.
  String? _account;

  /// The stored draft [restore] found and the director has not decided on.
  StoredDraft? _offer;

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

  /// Whether the director has started a contest that is not created yet.
  bool get hasDraft => !_draft.isBlank;

  /// When the draft was last saved, or `null` before the first save.
  DateTime? get savedAt => _savedAt;

  /// Whether the latest save failed.
  bool get saveFailed => _saveFailed;

  /// Whether the current account's stored draft has not been dealt with yet:
  /// [restore] has not looked at it, or it was offered and neither continued
  /// nor discarded (the director left before choosing).
  bool get needsRestore =>
      persistence != null &&
      (_account != persistence!.accountId || _offer != null);

  /// Looks for the current account's stored draft. A draft still in memory
  /// from another account is dropped first.
  ///
  /// Returns what the director must decide on: a [FoundStoredDraft] to
  /// continue or discard, an [UnreadableStoredDraft] to discard, or `null`
  /// when there is nothing to ask. Until the director decides ([continueWith]
  /// or [discard]) the same offer comes back, so leaving the wizard first
  /// loses nothing.
  Future<StoredDraft?> restore() async {
    final persistence = this.persistence;
    if (persistence == null || !needsRestore) {
      return null;
    }
    final account = persistence.accountId;
    if (_account != account) {
      if (_account != null) {
        // Another account is in now; its draft is not ours to show.
        _forget();
      }
      _offer = null;
    } else if (_offer != null) {
      return _offer;
    }
    final stored = await persistence.load(account);
    if (persistence.accountId != account) {
      // The account changed while loading; that draft is not for this one.
      return restore();
    }
    _account = account;
    return _offer = stored is NoStoredDraft ? null : stored;
  }

  /// Takes up a stored draft the director chose to continue.
  void continueWith(FoundStoredDraft stored) {
    _offer = null;
    _draft = stored.draft;
    _savedAt = stored.savedAt;
    _saveFailed = false;
    notifyListeners();
  }

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

  /// Drops the draft and its stored copy, for example once the contest is
  /// created or the director starts fresh. When the stored copy can't be
  /// deleted, [saveFailed] is set and [retry] tries again.
  Future<void> discard() async {
    final account = _account;
    _offer = null;
    _forget();
    notifyListeners();
    final persistence = this.persistence;
    if (account == null || persistence == null) {
      return;
    }
    try {
      await persistence.clear(account);
    } on Object {
      _saveFailed = true;
      notifyListeners();
    }
  }

  void _forget() {
    _draft = const ContestDraft();
    _savedAt = null;
    _saveFailed = false;
    _creationIds = null;
  }

  Future<void> _save() async {
    try {
      final now = _clock();
      final persistence = this.persistence;
      if (persistence != null) {
        await persistence.save(_account ??= persistence.accountId, _draft, now);
      }
      _savedAt = now;
      _saveFailed = false;
    } on Object {
      _saveFailed = true;
    }
    notifyListeners();
  }
}
