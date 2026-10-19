import '../errors/entity_not_found_error.dart';
import '../models/accounts/account.dart';
import '../models/accounts/account_preferences.dart';
import '../models/id.dart';
import '../repositories/account_repository.dart';
import '../repositories/repository.dart';

/// Reads and updates the preferences stored on the signed-in account.
class AccountPreferencesService {
  AccountPreferencesService(Repository repository)
    : _accounts = repository.accountRepository;

  final AccountRepository _accounts;

  /// The preferences of [accountId]. Throws [EntityNotFoundError] when the
  /// account does not exist.
  Future<AccountPreferences> get(Id accountId) async =>
      (await _find(accountId)).preferences;

  /// Replaces the preferences of [accountId] with [preferences] and returns
  /// them. A null field clears that choice.
  Future<AccountPreferences> update({
    required Id accountId,
    required AccountPreferences preferences,
    required DateTime now,
  }) async {
    final account = await _find(accountId);
    if (account.preferences == preferences) return preferences;
    final saved = await _accounts.save(
      account.withPreferences(preferences, now.toUtc()),
    );
    return saved.preferences;
  }

  Future<Account> _find(Id accountId) async {
    final account = await _accounts.findById(accountId);
    if (account == null) {
      throw EntityNotFoundError(entityType: 'Account', entityId: accountId);
    }
    return account;
  }
}
