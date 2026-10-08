import '../models/accounts/participant_account_link.dart';
import '../models/id.dart';

/// Abstract persistence contract for [ParticipantAccountLink]s.
///
/// Backend only: writes record no `MutationRecord`. Optimistic locking works
/// as it does for synchronized entities, through the `revision` the
/// repository bumps.
abstract interface class ParticipantAccountLinkRepository {
  Future<ParticipantAccountLink?> findById(Id id);

  /// The link between [participantProfileId] and [accountId], or `null`.
  Future<ParticipantAccountLink?> find({
    required Id participantProfileId,
    required Id accountId,
  });

  /// The confirmed link of [participantProfileId], or `null`. A profile has
  /// at most one.
  Future<ParticipantAccountLink?> findConfirmedForProfile(
    Id participantProfileId,
  );

  /// Every link of [participantProfileId], oldest first by id.
  Future<List<ParticipantAccountLink>> listForProfile(Id participantProfileId);

  /// Every link of [accountId], oldest first by id.
  Future<List<ParticipantAccountLink>> listForAccount(Id accountId);

  /// Stores [link], bumping its revision, and returns it as stored.
  ///
  /// A new link is stored at the revision it carries. Throws a
  /// `StaleRevisionError`, storing nothing, when [link] was read at an older
  /// revision than the stored one. The database refuses a second confirmed
  /// link for a profile, so a replacement ends the earlier link first.
  Future<ParticipantAccountLink> save(ParticipantAccountLink link);
}
