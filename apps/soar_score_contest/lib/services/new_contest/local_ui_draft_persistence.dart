import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import 'contest_draft.dart';
import 'contest_draft_codec.dart';
import 'draft_persistence.dart';

/// A stored draft as the storage layer sees it: the draft's own version, when
/// it was saved and the data, left undecoded so a draft from another version
/// can still be recognized and discarded.
class _Envelope {
  const _Envelope(this.version, this.savedAt, this.data);

  /// Reads whatever was stored; fields that are missing or the wrong type
  /// come out `null`, which makes the draft unreadable rather than missing.
  factory _Envelope.read(Object? raw) {
    if (raw is! Map) {
      return const _Envelope(null, null, null);
    }
    final version = raw['version'];
    final savedAt = raw['saved_at'];
    return _Envelope(
      version is int ? version : null,
      savedAt is String ? DateTime.tryParse(savedAt) : null,
      raw['data'],
    );
  }

  final int? version;
  final DateTime? savedAt;
  final Object? data;
}

/// Keeps the draft in the [LocalUiStore], under one key per account.
class LocalUiDraftPersistence implements DraftPersistence {
  LocalUiDraftPersistence(this._store, {required this.account});

  /// The key's own version stays 1: the draft's version lives in the envelope,
  /// because a key-level mismatch would read as "no draft" and hide an
  /// outdated one that should be offered for discard.
  static final LocalUiKey<_Envelope?> _key = LocalUiKey<_Envelope?>(
    name: 'new_contest_draft',
    defaultValue: null,
    // Damaged text or another storage version is a draft that can only be
    // discarded, not an absent one.
    unreadable: () => const _Envelope(null, null, null),
    encode: (value) => value == null
        ? null
        : {
            'version': value.version,
            'saved_at': value.savedAt?.toUtc().toIso8601String(),
            'data': value.data,
          },
    decode: (data) => data == null ? null : _Envelope.read(data),
  );

  final LocalUiStore _store;

  /// Gives the account whose draft is current now.
  final String Function() account;

  @override
  String get accountId => account();

  @override
  Future<StoredDraft> load(String accountId) async {
    final envelope = await _store.get(accountId, _key);
    if (envelope == null) {
      return const NoStoredDraft();
    }
    final savedAt = envelope.savedAt;
    if (envelope.version != ContestDraftCodec.version || savedAt == null) {
      return UnreadableStoredDraft(savedAt);
    }
    try {
      final draft = ContestDraftCodec.decode(envelope.data);
      return draft.isBlank
          ? const NoStoredDraft()
          : FoundStoredDraft(draft, savedAt);
    } on FormatException {
      return UnreadableStoredDraft(savedAt);
    }
  }

  @override
  Future<void> save(
    String accountId,
    ContestDraft draft,
    DateTime savedAt,
  ) async {
    final saved = draft.isBlank
        ? await _store.remove(accountId, _key)
        : await _store.set(
            accountId,
            _key,
            _Envelope(
              ContestDraftCodec.version,
              savedAt,
              ContestDraftCodec.encode(draft),
            ),
          );
    if (!saved) {
      throw StateError('The draft could not be stored.');
    }
  }

  @override
  Future<void> clear(String accountId) async {
    if (!await _store.remove(accountId, _key)) {
      throw StateError('The draft could not be deleted.');
    }
  }
}
