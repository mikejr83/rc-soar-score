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
}
