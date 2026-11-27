import 'dart:async';

import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import 'participant_candidate.dart';

/// Where a director finds listed pilots in the directory and copies one into
/// their own pilot list (#653).
///
/// The directory lives on the hosted server, so [hosted] is the client that
/// signs in there; the copy becomes a profile on [local] (the same client on
/// the web). Lookups are exact (a verified email, an FAI number or a national
/// ID), so [search] waits for the typing to pause and ignores text that
/// cannot be one of those (names, partial emails). The server limits how many
/// lookups an account can make; one that is refused is
/// [DirectoryRateLimited].
class DirectoryPilotSource {
  DirectoryPilotSource({
    required this.hosted,
    required this.local,
    this.pause = const Duration(milliseconds: 600),
    this.store,
    this.accountId = '',
    this.answerLife = const Duration(seconds: 30),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Where the copies this director made are remembered on this device, so a
  /// pilot copied before the profile reached the server is still recognised
  /// after the app restarts (the server names the copy once it has synced).
  final LocalUiStore? store;

  /// The account whose copies [store] holds.
  final String accountId;

  final ApiClient hosted;
  final ApiClient local;
  final Duration pause;

  /// How long an answer to typed text is reused. A pilot can list or correct
  /// their entry at any time, so an explicit [lookup] never reuses one.
  final Duration answerLife;
  final DateTime Function() _clock;

  int _typed = 0;
  final Map<String, ({DateTime at, _Found found})> _answers = {};

  /// The profile id a copy of each directory entry gets, kept so choosing the
  /// same pilot again (after a failure, or in another search) is the same copy.
  final Map<String, Id> _profileIds = {};
  Future<void>? _loaded;

  /// The directory entry id -> profile id of every copy made on this device.
  static final copiesKey = LocalUiKey<Map<String, String>>(
    name: 'directory_copies',
    defaultValue: const <String, String>{},
    encode: (copies) => copies,
    decode: (data) => {
      if (data is Map)
        for (final e in data.entries)
          if (e.key is String && e.value is String)
            e.key as String: e.value as String,
    },
  );

  Future<void> _load() => _loaded ??= () async {
    final remembered = await store?.get(accountId, copiesKey);
    for (final e in (remembered ?? const <String, String>{}).entries) {
      try {
        _profileIds.putIfAbsent(e.key, () => Id.parse(e.value));
      } on ArgumentError {
        // A value that is not an id is forgotten.
      }
    }
  }();

  /// An address whose last part looks like a top-level domain (letters only,
  /// at least two), so text that is still being typed (`a@b.c`) makes no
  /// request. The server limits how many lookups an account can make.
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[A-Za-z]{2,}$');

  /// The listed pilots whose email, FAI number or national ID is exactly
  /// [query], as the director types: empty while the text is not yet any of
  /// those (a name makes no lookup), or when a newer change arrived during the
  /// pause.
  Future<List<ParticipantCandidate>> search(String query) async {
    // Any change of the text ends the wait of an earlier one.
    final mine = ++_typed;
    final text = query.trim();
    final keys = _typedKeys(text);
    if (keys.isEmpty) return const [];
    final cached = _answers[_cacheKey(text, keys)];
    if (cached != null && _clock().difference(cached.at) < answerLife) {
      return _candidates(cached.found);
    }
    await Future<void>.delayed(pause);
    if (mine != _typed) return const [];
    return _lookup(text, keys);
  }

  /// The same lookup the director asked for on purpose, for an ID the typing
  /// rules skip (a short one, one with letters only or with spaces). No
  /// pause, since asking is the pause; the server's limit still applies.
  Future<List<ParticipantCandidate>> lookup(String query) async {
    ++_typed;
    final text = query.trim();
    if (text.isEmpty || text.length > maxLookupLength) return const [];
    // Asked on purpose, any text is also an ID, even one with an `@`.
    return _lookup(text, _keysFor(text));
  }

  /// The longest text a lookup takes.
  static const maxLookupLength = 64;

  /// Emails ignore case, but text that is also asked as an ID is matched
  /// exactly, so two spellings that differ only by case are two questions.
  static String _cacheKey(String text, List<DirectoryLookupKeyDto> keys) =>
      keys.length == 1 ? text.toLowerCase() : text;

  static const _idKeys = [
    DirectoryLookupKeyDto.faiNumber,
    DirectoryLookupKeyDto.nationalOrgId,
  ];

  /// Text with an `@` may be an email and also an ID that happens to contain
  /// one.
  static List<DirectoryLookupKeyDto> _keysFor(String text) => [
    // Asked on purpose, anything with an `@` may be an address, whatever its
    // last part (a punycode TLD); the server decides what it holds.
    if (text.contains('@')) DirectoryLookupKeyDto.email,
    ..._idKeys,
  ];

  Future<List<ParticipantCandidate>> _lookup(
    String text,
    List<DirectoryLookupKeyDto> keys,
  ) async {
    await _load();
    final found = <String, DirectoryMatchDto>{};
    final viaEmail = <String>{};
    // The ID another listed pilot also holds, by entry: the answer of the key
    // that flagged it (a later answer of another key must not clear it).
    final shared = <String, String>{};
    Object? failure;
    for (final key in keys) {
      final DirectoryLookupResponse response;
      try {
        response = await hosted.lookupDirectory(
          DirectoryLookupRequest(key: key, value: text),
        );
      } on Object catch (e) {
        // One key failing keeps what the others found. A refused (too many)
        // request ends the rest, which would be refused too.
        failure = _worse(failure, e);
        if (_isRateLimit(e)) break;
        continue;
      }
      for (final match in response.results) {
        found[match.entryId.value] = match;
        if (match.sharedKey) {
          final id = key == DirectoryLookupKeyDto.faiNumber
              ? match.faiNumber
              : match.nationalOrgId;
          if (id != null) shared.putIfAbsent(match.entryId.value, () => id);
        }
        if (key == DirectoryLookupKeyDto.email) {
          viaEmail.add(match.entryId.value);
        }
      }
    }
    final answer = _Found(text, found.values.toList(), viaEmail, shared);
    if (failure != null) {
      // Partial answers are shown but not reused: the key that failed was
      // never asked.
      if (found.isEmpty) {
        throw _isRateLimit(failure) ? const DirectoryRateLimited() : failure;
      }
      return _candidates(answer);
    }
    _answers[_cacheKey(text, keys)] = (at: _clock(), found: answer);
    return _candidates(answer);
  }

  static bool _isRateLimit(Object e) =>
      e is ApiHttpError && e.statusCode == 429;

  /// The failure worth reporting: a rate limit over any other.
  static Object _worse(Object? earlier, Object e) =>
      earlier != null && _isRateLimit(earlier) ? earlier : e;

  List<ParticipantCandidate> _candidates(_Found answer) => [
    for (final match in answer.matches)
      ParticipantCandidate.directory(
        match,
        // The copy the server knows this director already made, else the id
        // chosen for this session.
        profileId:
            match.copiedProfileId ??
            _profileIds.putIfAbsent(match.entryId.value, Id.create),
        // The typed email only names entries the email lookup returned,
        // never one an ID lookup found.
        searchedEmail: answer.viaEmail.contains(match.entryId.value)
            ? answer.text
            : null,
        sharedId: answer.shared[match.entryId.value],
      ),
  ];

  static List<DirectoryLookupKeyDto> _typedKeys(String text) {
    // An email is looked up whatever it contains; FAI numbers and national IDs
    // usually carry digits and a name never does, so typing a name makes no
    // lookup. Other IDs use [lookup].
    if (_email.hasMatch(text)) return const [DirectoryLookupKeyDto.email];
    // Text with an `@` is an email being typed; an ID that contains one is
    // asked on purpose with [lookup].
    final idLike =
        text.length >= 4 &&
        !text.contains(RegExp(r'[\s@]')) &&
        text.contains(RegExp(r'\d'));
    return idLike ? _idKeys : const [];
  }

  /// Copies the directory pilot [candidate] into the director's pilot list:
  /// the server links the pilot's account to the profile, then the profile is
  /// made from the details it returned (the email only when the pilot shared
  /// it). The profile is the director's own and is never changed by the
  /// pilot's account afterwards. Choosing the same pilot twice is the same
  /// profile.
  ///
  /// Throws [ApiHttpError] when the server refuses (for example the pilot
  /// has just stopped being listed, status 404).
  Future<ParticipantProfile> copy(ParticipantCandidate candidate) async {
    final entry = candidate.directory;
    if (entry == null) {
      throw ArgumentError.value(
        candidate,
        'candidate',
        'not a directory pilot',
      );
    }
    // Remember the id before asking: the server may commit the link and the
    // answer be lost, and a retry must name the same profile.
    await _remember(entry.entryId, candidate.profileId);
    // A refusal of this attempt does not say an earlier one failed (its answer
    // may have been lost after the server linked), so the id is kept.
    final details = await hosted.copyDirectoryEntry(
      DirectoryCopyRequest(
        entryId: entry.entryId,
        profileId: candidate.profileId,
      ),
    );
    try {
      return await local.createParticipant(
        CreateParticipantRequest(
          id: candidate.profileId,
          firstName: details.firstName,
          lastName: details.lastName,
          club: details.club,
          faiNumber: details.faiNumber,
          nationalOrgId: details.nationalOrgId,
          city: details.city,
          state: details.state,
          country: details.country,
          email: details.email,
        ),
      );
    } on ApiHttpError catch (e) {
      // The profile exists under this id with other details: an earlier
      // create got through and its answer was lost, and the pilot has
      // changed their entry since. Take it as it is; the director's copy is
      // never overwritten (a refresh offers the new details).
      if (e.statusCode != 409) rethrow;
      return local.participant(candidate.profileId);
    }
  }

  Future<void> _remember(Id entryId, Id profileId) async {
    _profileIds[entryId.value] = profileId;
    final kept = store;
    if (kept == null) return;
    final copies = {...await kept.get(accountId, copiesKey)};
    copies[entryId.value] = profileId.value;
    await kept.set(accountId, copiesKey, copies);
  }
}

/// The server refused a lookup because this account asked too often (429).
class DirectoryRateLimited implements Exception {
  const DirectoryRateLimited();

  @override
  String toString() => 'DirectoryRateLimited';
}

/// The answer to one lookup and which entries the email key returned.
class _Found {
  const _Found(this.text, this.matches, this.viaEmail, this.shared);

  final String text;
  final List<DirectoryMatchDto> matches;
  final Set<String> viaEmail;

  /// Entry id -> the ID it shares with another listed pilot.
  final Map<String, String> shared;
}
