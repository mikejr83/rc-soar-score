import 'package:drift/drift.dart' show DriftSqlType;
import 'package:soar_score_data/schema/guest_account_references.dart';
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

/// Columns whose names look like account references but hold something else.
const _notAccounts = {
  're_flight_participants.responded_by', // a role, not an account
  'discipline_profiles.superseded_by', // a discipline profile, not an account
};

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;

  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
  });
  tearDown(() => inst.close());

  // A claim of a pilot's guest entries re-points what a guest can hold. A
  // column that can name an account, on any table of the server, must be
  // either re-pointed or explained, so a new one cannot be forgotten.
  test('every account column is claimed or explained', () {
    final accountLike = RegExp(
      r'(account_id|actor_id|_by$|^owner_account_id$|actor|requester|redeemed)',
    );
    final claimed = {
      for (final MapEntry(key: table, value: columns)
          in guestAccountReferences.entries)
        for (final column in columns) '$table.$column',
    };
    final missing = <String>[];
    for (final table in inst.db.profileTables) {
      for (final column in table.$columns) {
        final name = '${table.actualTableName}.${column.name}';
        if (column.type == DriftSqlType.string &&
            accountLike.hasMatch(column.name) &&
            !claimed.contains(name) &&
            !accountColumnsGuestsNeverHold.containsKey(name) &&
            !_notAccounts.contains(name)) {
          missing.add(name);
        }
      }
    }
    expect(
      missing,
      isEmpty,
      reason:
          'list each in guestAccountReferences (a guest can hold it) or in '
          'accountColumnsGuestsNeverHold with the reason',
    );
    for (final name in claimed) {
      final (table, column) = (name.split('.')[0], name.split('.')[1]);
      expect(
        inst.db.profileTables.any(
          (t) =>
              t.actualTableName == table &&
              t.$columns.any((c) => c.name == column),
        ),
        isTrue,
        reason: '$name is listed but not in the schema',
      );
    }
  });
}
