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

  /// Takes the right to refresh [id]'s profile: sets `profile_refreshed_at`
  /// to [at] only while it still equals [expected] (null for never), in one
  /// atomic statement. Returns false when another request took it first or
  /// the account is gone; only the winner asks the identity provider.
  Future<bool> claimProfileRefresh(
    Id id, {
    required DateTime? expected,
    required DateTime at,
  });

  /// Stores the identity provider's [firstName], [lastName], [email] and
  /// [emailVerified] on [id], touching no other column (a concurrent
  /// preference change is not overwritten). Returns false when the account
  /// is gone.
  ///
  /// Throws when [email] belongs to another account; the caller then keeps
  /// the stored email.
  Future<bool> applyProfile(
    Id id, {
    required String firstName,
    required String lastName,
    required String? email,
    required bool emailVerified,
    required DateTime now,
  });

  /// Clears [email] from the registered account [id], in one conditional
  /// write that applies only while that account still holds exactly [email]
  /// unverified. Touches the email columns only. Returns whether it released
  /// the address; false means the account changed meanwhile (the address was
  /// verified, replaced or removed) and the caller looks again.
  Future<bool> releaseUnverifiedEmail(
    Id id,
    String email, {
    required DateTime now,
  });
}
