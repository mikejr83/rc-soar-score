import 'local_ui_key.dart';

/// UI-only state kept on the client and never synchronized: theme, hidden
/// panels, drafts. Contest data never goes through it.
///
/// Every call names the account whose state it touches, so two accounts on one
/// machine never see each other's values. The Local account is an account like
/// any other here.
///
/// Calls never throw: a failed read gives the key's default and a failed write
/// returns `false`, both logged.
abstract class LocalUiStore {
  /// The value stored for [accountId] under [key], or the key's default when
  /// there is none or it cannot be used.
  Future<T> get<T>(String accountId, LocalUiKey<T> key);

  /// Stores [value]; returns whether it was saved.
  Future<bool> set<T>(String accountId, LocalUiKey<T> key, T value);

  /// Forgets the stored value, so reads give the default again; returns
  /// whether it was removed.
  Future<bool> remove<T>(String accountId, LocalUiKey<T> key);

  /// The current value, then each later change made through this store.
  Stream<T> watch<T>(String accountId, LocalUiKey<T> key);

  /// Releases what the store holds open.
  Future<void> close();
}
