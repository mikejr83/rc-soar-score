import 'dart:async';

import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

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
  });

  final ApiClient hosted;
  final ApiClient local;
  final Duration pause;

  int _typed = 0;
  final Map<String, List<DirectoryMatchDto>> _answers = {};

  /// The profile id a copy of each directory entry gets, kept so choosing the
  /// same pilot again (after a failure, or in another search) is the same copy.
  final Map<String, Id> _profileIds = {};

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// The listed pilots whose email, FAI number or national ID is exactly
  /// [query]; empty while the text is not yet any of those, or when a newer
  /// query arrived during the pause.
  Future<List<ParticipantCandidate>> search(String query) async {
    final text = query.trim();
    final keys = _keysFor(text);
    if (keys.isEmpty) return const [];
    final cached = _answers[text.toLowerCase()];
    if (cached != null) return _candidates(cached);
    final mine = ++_typed;
    await Future<void>.delayed(pause);
    if (mine != _typed) return const [];
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
    _answers[text.toLowerCase()] = matches;
    return _candidates(matches);
  }

  List<ParticipantCandidate> _candidates(List<DirectoryMatchDto> matches) => [
    for (final match in matches)
      ParticipantCandidate.directory(
        match,
        profileId: _profileIds.putIfAbsent(match.entryId.value, Id.create),
      ),
  ];

  static List<DirectoryLookupKeyDto> _keysFor(String text) {
    if (text.contains('@')) {
      return _email.hasMatch(text) ? [DirectoryLookupKeyDto.email] : const [];
    }
    // FAI numbers and national IDs carry digits; a name never does, so typing
    // a name makes no lookup.
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
}
