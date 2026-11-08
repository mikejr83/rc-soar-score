import 'package:drift/drift.dart';

/// The installation's own Local account id.
///
/// Client only. Accounts are held by the backend and not synchronized, so an
/// installation keeps just the id of the Local account that owns what it
/// creates offline. The id is an opaque reference: nothing has a foreign key
/// to it. The table holds at most one row.
@DataClassName('LocalAccountData')
class LocalAccount extends Table {
  /// Always 1, so a second row cannot be inserted.
  IntColumn get slot => integer().check(slot.equals(1))();

  /// The Local account id (UUIDv7), generated on first run and never changed.
  TextColumn get accountId => text()();

  /// Preferences chosen on this installation (see `AccountPreferences`);
  /// null until chosen.
  TextColumn get preferredTimeZone => text().nullable()();
  TextColumn get preferredLocale => text().nullable()();

  /// The registered account this installation's data was last claimed into
  /// (see `LocalAccountRepository.reassignTo`); null until a claim. Kept so the
  /// installation keeps acting as that account when it starts offline or the
  /// director signs out.
  TextColumn get linkedAccountId => text().nullable()();

  /// The identity provider's stable id (Auth0 `sub`) of the sign-in that
  /// claimed the data; null until a claim. The app compares it with the
  /// signed-in user before serving the linked account's data, so a different
  /// sign-in cannot reach it, even offline.
  TextColumn get linkedSubject => text().nullable()();

  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {slot};
}
