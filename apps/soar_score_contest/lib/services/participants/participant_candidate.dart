import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../widgets/participant_search.dart';
import 'participant_row.dart';

/// A person the participant search found.
class ParticipantCandidate {
  const ParticipantCandidate({
    required this.profileId,
    required this.name,
    required this.source,
    this.club,
    this.email,
    this.emailVisible = true,
    this.directory,
    this.searchedEmail,
  });

  /// A listed pilot the directory found (#653). [profileId] is the id the
  /// director's copy will have; nothing exists under it yet.
  factory ParticipantCandidate.directory(
    DirectoryMatchDto match, {
    required Id profileId,
    String? searchedEmail,
  }) => ParticipantCandidate(
    profileId: profileId,
    name: '${match.firstName} ${match.lastName}',
    source: ParticipantSource.remote,
    club: match.club,
    email: match.email,
    emailVisible: match.email != null,
    directory: match,
    searchedEmail: searchedEmail,
  );

  /// One of the director's own [profile]s (its email is always shown).
  factory ParticipantCandidate.local(ParticipantProfile profile) =>
      ParticipantCandidate(
        profileId: profile.id,
        name: '${profile.firstName} ${profile.lastName}',
        source: ParticipantSource.local,
        club: profile.club,
        email: profile.email,
      );

  final Id profileId;
  final String name;
  final ParticipantSource source;
  final String? club;
  final String? email;

  /// Whether [email] may be shown. Remote profiles show it only with the
  /// person's permission; the email must not even reach the UI otherwise.
  final bool emailVisible;

  /// The directory entry this person was found as, or null for one of the
  /// director's own profiles. A copy of it becomes their profile.
  final DirectoryMatchDto? directory;

  /// The email the director typed to find this pilot, which the pilot may
  /// keep private from the result: still enough to see a profile of the
  /// director's already holds it.
  final String? searchedEmail;

  /// The director's own [profiles] that already hold this directory pilot:
  /// the copy made before, or one with the same FAI number, national ID or
  /// email (the email the pilot shows, else the one the director typed).
  List<ParticipantProfile> copiesIn(Iterable<ParticipantProfile> profiles) {
    final match = directory;
    if (match == null) return const [];
    bool same(String? a, String? b) =>
        a != null &&
        b != null &&
        a.trim().toLowerCase() == b.trim().toLowerCase();
    return [
      for (final p in profiles)
        if (p.id == profileId ||
            same(p.faiNumber, match.faiNumber) ||
            same(p.nationalOrgId, match.nationalOrgId) ||
            same(p.email, match.email ?? searchedEmail))
          p,
    ];
  }

  /// Whether one of the director's own [profiles] already holds this pilot.
  bool isCopiedIn(Iterable<ParticipantProfile> profiles) =>
      copiesIn(profiles).isNotEmpty;

  /// What the email cell says for this person.
  ParticipantEmailStatus get emailStatus {
    if (source == ParticipantSource.remote && !emailVisible) {
      return ParticipantEmailStatus.private;
    }
    final address = email;
    return address == null || address.isEmpty
        ? ParticipantEmailStatus.none
        : ParticipantEmailStatus.has;
  }
}

/// Searches the remote participant directory (see `DirectoryPilotSource`).
/// Without one the search only lists the director's own profiles; with one,
/// remote results are listed first.
typedef RemoteParticipantSearch = Future<List<ParticipantCandidate>> Function(
  String query,
);

/// The director's own profiles matching [query] (every word must match a
/// name, email, FAI number or national ID).
List<ParticipantCandidate> searchLocalProfiles(
  List<ParticipantProfile> profiles,
  String query,
) => [
  for (final profile in profiles)
    if (query.trim().isNotEmpty && matchesParticipantSearch(profile, query))
      ParticipantCandidate.local(profile),
];
