import '../models/publication/publication_identity.dart';
import '../models/publication/publication_participant.dart';
import '../models/publication/publication_projection.dart';
import '../models/sync/audit_event.dart';

/// Stores everything one successful publish changes, all or nothing.
///
/// Readers see either the previous complete projection or the new one, never
/// a publication whose identity points at a projection that is not there.
/// Backend only: writes record no `MutationRecord`.
abstract interface class PublicationPublisher {
  /// Stores [identity] (a new one, or an existing one read at its current
  /// revision), the [participants] rows, the new [projection] and the
  /// success [attempt] event together, and returns the identity as stored.
  ///
  /// Throws a `StaleRevisionError`, storing nothing, when [identity] was read
  /// at an older revision than the stored one.
  Future<PublicationIdentity> publish({
    required PublicationIdentity identity,
    required Iterable<PublicationParticipant> participants,
    required PublicationProjection projection,
    required AuditEvent attempt,
  });
}
