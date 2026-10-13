import '../models/accounts/account_alias.dart';
import '../models/id.dart';

/// Abstract persistence contract for [AccountAlias]es, the Local account ids
/// that were claimed into registered accounts.
///
/// Backend only: writes record no `MutationRecord`.
abstract interface class AccountAliasRepository {
  /// The alias for the Local account [id], or `null` if it was never claimed.
  Future<AccountAlias?> findById(Id id);

  /// Every alias of [accountId], oldest first by id.
  Future<List<AccountAlias>> listForAccount(Id accountId);

  /// Records that the Local account [localAccountId] belongs to [accountId]
  /// and returns the stored alias.
  ///
  /// A claim never moves: when the id is already an alias, nothing is
  /// written and the stored alias is returned, whichever account it names.
  /// The caller compares [AccountAlias.accountId] with [accountId] to tell a
  /// repeated claim from a conflicting one.
  Future<AccountAlias> claim({
    required Id localAccountId,
    required Id accountId,
    required DateTime claimedAt,
  });

  /// The account [id] stands for: the registered account when [id] is a
  /// claimed Local account id, otherwise [id] itself.
  Future<Id> resolve(Id id);
}
