import '../errors/account_claim_error.dart';
import '../models/accounts/account_alias.dart';
import '../models/id.dart';
import '../repositories/account_alias_repository.dart';
import '../repositories/account_repository.dart';
import '../repositories/repository.dart';

/// Claims an installation's Local account into the signed-in account.
///
/// The claim is recorded as an [AccountAlias]; the backend holds no data
/// under a Local id until it is claimed, so nothing is re-pointed here.
/// Re-pointing the installation's own rows is the client's part of a claim.
class AccountClaimsService {
  AccountClaimsService(Repository repository)
    : _aliases = repository.accountAliasRepository,
      _accounts = repository.accountRepository;

  final AccountAliasRepository _aliases;
  final AccountRepository _accounts;

  /// Claims [localAccountId] into [accountId], the signed-in account.
  ///
  /// Claiming the same id again for the same account returns the stored alias
  /// and changes nothing. Throws an [ArgumentError] when [localAccountId] is
  /// the account's own id or belongs to an existing account, so a claim can
  /// never capture another person's id, and an [AccountClaimError] when the
  /// id was claimed into a different account.
  Future<AccountAlias> claimLocalAccount({
    required Id accountId,
    required Id localAccountId,
    required DateTime now,
  }) async {
    if (localAccountId == accountId ||
        await _accounts.findById(localAccountId) != null) {
      throw ArgumentError.value(
        localAccountId.value,
        'local_account_id',
        'is the id of an account, not of a Local account',
      );
    }
    final alias = await _aliases.claim(
      localAccountId: localAccountId,
      accountId: accountId,
      claimedAt: now,
    );
    if (alias.accountId != accountId) {
      throw AccountClaimError.alreadyClaimed();
    }
    return alias;
  }
}
