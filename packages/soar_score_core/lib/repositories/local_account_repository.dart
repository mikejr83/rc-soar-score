import '../models/accounts/account_preferences.dart';
import '../models/id.dart';

/// Abstract persistence contract for the installation's own Local account.
///
/// The Local account owns what the installation creates offline and is the
/// actor of its local writes. It is later claimed into a registered account.
abstract interface class LocalAccountRepository {
  /// The Local account id, or null before the first run created it.
  Future<Id?> find();

  /// The Local account id, creating it when this is the first run.
  ///
  /// Idempotent: the id is generated once and every later call, including
  /// after sign-in, returns the same one.
  Future<Id> ensure();

  /// Re-points everything that names the Local account to [accountId]: the
  /// ownership of contests and director data, the actors of writes already
  /// made, and the owner and payload of mutations still waiting to be sent.
  ///
  /// All or nothing, and idempotent: a second call finds nothing left to
  /// change. The Local account id itself is kept, so the claim can be
  /// repeated and late records that still carry it can be recognised. Throws
  /// [StateError] before the first run created the Local account and
  /// [ArgumentError] when [accountId] is the Local account id.
  Future<void> reassignTo(Id accountId);

  /// The preferences chosen on this installation; empty before any choice.
  Future<AccountPreferences> preferences();

  /// Stores [preferences] as the installation's own, replacing the stored
  /// ones. Throws [StateError] before the first run created the Local account.
  Future<void> savePreferences(AccountPreferences preferences);
}
