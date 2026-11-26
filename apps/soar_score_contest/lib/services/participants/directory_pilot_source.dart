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
/// cannot be one of those (names, partial emails); the server limits how many lookups an account can
/// make.
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
  final Map<String, ({DateTime at, List<DirectoryMatchDto> matches})> _answers =
      {};

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

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

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
    final cached = _answers[_cacheKey(text)];
    if (cached != null && _clock().difference(cached.at) < answerLife) {
      return _candidates(cached.matches, text);
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
    final keys = text.contains('@')
        ? _typedKeys(text)
        : const [
            DirectoryLookupKeyDto.faiNumber,
            DirectoryLookupKeyDto.nationalOrgId,
          ];
    if (keys.isEmpty) return const [];
    return _lookup(text, keys);
  }

  /// The longest text a lookup takes.
  static const maxLookupLength = 64;

  /// Emails ignore case; IDs are matched exactly.
  static String _cacheKey(String text) =>
      text.contains('@') ? text.toLowerCase() : text;

  Future<List<ParticipantCandidate>> _lookup(
    String text,
    List<DirectoryLookupKeyDto> keys,
  ) async {
    await _load();
    final found = <String, DirectoryMatchDto>{};
    for (final key in keys) {
      final response = await hosted.lookupDirectory(
        DirectoryLookupRequest(key: key, value: text),
      );
      for (final match in response.results) {
        found[match.entryId.value] = match;
      }
    }
    final matches = found.values.toList();
    _answers[_cacheKey(text)] = (at: _clock(), matches: matches);
    return _candidates(matches, text);
  }

  List<ParticipantCandidate> _candidates(
    List<DirectoryMatchDto> matches,
    String text,
  ) => [
    for (final match in matches)
      ParticipantCandidate.directory(
        match,
        // The copy the server knows this director already made, else the id
        // chosen for this session.
        profileId:
            match.copiedProfileId ??
            _profileIds.putIfAbsent(match.entryId.value, Id.create),
        searchedEmail: text.contains('@') ? text : null,
      ),
  ];

  static List<DirectoryLookupKeyDto> _typedKeys(String text) {
    if (text.contains('@')) {
      return _email.hasMatch(text) ? [DirectoryLookupKeyDto.email] : const [];
    }
    // FAI numbers and national IDs usually carry digits; a name never does,
    // so typing a name makes no lookup. Other IDs use [lookup].
    if (text.length < 4 ||
        text.contains(RegExp(r'\s')) ||
        !text.contains(RegExp(r'\d'))) {
      return const [];
    }
    return [
      DirectoryLookupKeyDto.faiNumber,
      DirectoryLookupKeyDto.nationalOrgId,
    ];
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
    return local.createParticipant(
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
