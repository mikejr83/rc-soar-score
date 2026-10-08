import '../models/accounts/account_identity.dart';
import '../models/id.dart';

/// Abstract persistence contract for [AccountIdentity]s, the identity
/// provider subjects an account signs in with.
///
/// Backend only: writes record no `MutationRecord`.
abstract interface class AccountIdentityRepository {
  Future<AccountIdentity?> findById(Id id);

  /// The identity of [subject] at [issuer], or `null`. A subject is only
  /// meaningful together with its issuer.
  Future<AccountIdentity?> findBySubject({
    required String issuer,
    required String subject,
  });

  /// Every identity of [accountId], oldest first by id.
  Future<List<AccountIdentity>> listForAccount(Id accountId);

  /// Stores [identity], replacing the stored one with the same id. The
  /// database refuses a second identity for the same issuer and subject.
  Future<AccountIdentity> save(AccountIdentity identity);

  /// Removes the identity with [id]; returns whether one existed.
  Future<bool> remove(Id id);
}
