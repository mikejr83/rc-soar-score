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

  /// Every link of any of [participantProfileIds], in one bulk lookup.
  Future<List<ParticipantAccountLink>> listForProfiles(
    Iterable<Id> participantProfileIds,
  );

  /// Stores [link] as [save] does and, in the same transaction, makes the
  /// account of [link] the owner of what the guest accounts in
  /// [guestAccountIds] hold: their score attempts, the invitations they
  /// redeemed, and their audit events and mutation records.
  ///
  /// Either both happen or neither. Repeating it is a no-op once nothing is
  /// held by the guests. The guest account rows are kept.
  Future<ParticipantAccountLink> saveClaimingGuests(
    ParticipantAccountLink link, {
    required Iterable<Id> guestAccountIds,
  });

  /// Makes the account of [link] the owner of what the guest accounts in
  /// [guestAccountIds] hold, as [saveClaimingGuests] does, without storing or
  /// changing any link, in one transaction. For a link the caller read as
  /// Confirmed.
  ///
  /// The transaction first locks the stored link and checks that it is still
  /// Confirmed for the same account and profile; it returns false and claims
  /// nothing otherwise, so a claim cannot run after the link ended or moved.
  /// Ending the link waits for a claim in progress and the other way round.
  /// Two claims by one account never conflict, and repeating it is a no-op
  /// once nothing is held by the guests.
  Future<bool> claimGuests(
    ParticipantAccountLink link, {
    required Iterable<Id> guestAccountIds,
  });

  /// Stores [link] as [save] does and, in the same transaction, hands each
  /// invitation in the map [releases] returns (by invitation id) that the
  /// account of [link] holds back to the guest account named by its value, or
  /// to nobody when that guest account does not exist or the value is null.
  /// Score attempts stay with the account.
  ///
  /// [releases] runs inside the transaction, after the stored link has been
  /// locked with the lock [claimGuests] takes, so it sees every claim that
  /// completed before and none can complete after. An invitation in the map
  /// that the account does not hold is left alone.
  Future<ParticipantAccountLink> saveReleasingInvitations(
    ParticipantAccountLink link, {
    required Future<Map<Id, Id?>> Function() releases,
  });

  /// Stores [link], bumping its revision, and returns it as stored.
  ///
  /// A new link is stored at the revision it carries. Throws a
  /// `StaleRevisionError`, storing nothing, when [link] was read at an older
  /// revision than the stored one. The database refuses a second confirmed
  /// link for a profile, so a replacement ends the earlier link first.
  Future<ParticipantAccountLink> save(ParticipantAccountLink link);
}
