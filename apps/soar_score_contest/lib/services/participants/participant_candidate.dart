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
  });

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

/// Searches the remote participant directory. There is no directory
/// endpoint yet, so the wizard runs without one; when it exists, pass one to
/// the Participants step and remote results are listed first.
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
