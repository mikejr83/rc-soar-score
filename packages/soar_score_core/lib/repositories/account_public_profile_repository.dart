import '../models/accounts/account_public_profile.dart';
import '../models/id.dart';

/// Abstract persistence contract for [AccountPublicProfile]s.
///
/// Backend only: writes record no `MutationRecord`. A profile is unlinked
/// from its account by saving it with a null account id, never deleted,
/// because publications still reference it.
abstract interface class AccountPublicProfileRepository {
  Future<AccountPublicProfile?> findById(Id id);

  /// The public profile of [accountId], or `null` when it has none.
  Future<AccountPublicProfile?> findForAccount(Id accountId);

  /// Stores [profile], replacing the stored one with the same id. The
  /// database refuses a second profile for an account.
  Future<AccountPublicProfile> save(AccountPublicProfile profile);
}
