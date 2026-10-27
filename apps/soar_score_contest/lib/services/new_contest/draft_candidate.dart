import '../participants/participant_candidate.dart';
import 'draft_participant.dart';

extension DraftCandidate on ParticipantCandidate {
  /// A new Pilot row for this person.
  DraftParticipant toParticipant() => DraftParticipant(
    profileId: profileId,
    name: name,
    email: emailVisible ? email : null,
    emailVisible: emailVisible,
    source: source,
  );
}
