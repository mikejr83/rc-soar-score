import '../models/accounts/account.dart';
import '../models/id.dart';

/// Abstract persistence contract for [Account]s.
///
/// Accounts are backend only: they never synchronize, so writes record no
/// `MutationRecord`.
abstract interface class AccountRepository {
  Future<Account?> findById(Id id);

  /// The account with [email], or `null`. Emails are stored in lowercase, so
  /// the match ignores case.
  Future<Account?> findByEmail(String email);

  /// The single shared deleted-user account, or `null` before the system
  /// created it.
  Future<Account?> findDeletedUser();

  /// Stores [account], replacing the stored one with the same id.
  ///
  /// The database refuses a second account with the same email and a second
  /// deleted-user account.
  Future<Account> save(Account account);
}
