import '../models/id.dart';
import '../models/publication/publication_participant.dart';

/// Abstract persistence contract for [PublicationParticipant]s.
///
/// Backend only: writes record no `MutationRecord`.
abstract interface class PublicationParticipantRepository {
  Future<PublicationParticipant?> findById(Id id);

  /// The participant of [publicationId] with [pilotKey], or `null`.
  Future<PublicationParticipant?> findByPilotKey(
    Id publicationId,
    String pilotKey,
  );

  /// Every participant of [publicationId], in id order.
  Future<List<PublicationParticipant>> listForPublication(Id publicationId);

  /// Stores [participant], replacing the stored one with the same id.
  ///
  /// Redacting a participant is a save of the redacted copy. The last write
  /// wins; the caller decides when that is safe. A second participant with
  /// the same pilot key in a publication is refused by the database.
  Future<PublicationParticipant> save(PublicationParticipant participant);
}
