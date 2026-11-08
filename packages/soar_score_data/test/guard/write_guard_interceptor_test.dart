import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

void main() {
  late List<String> log;
  late bool refuseCommit;
  late bool refuseWrite;
  late SoarScoreDatabase db;

  setUp(() {
    log = [];
    refuseCommit = false;
    refuseWrite = false;
    db = SoarScoreDatabase(
      NativeDatabase.memory().interceptWith(
        WriteGuardInterceptor(
          beforeWrite: () async {
            log.add('write');
            if (refuseWrite) throw StateError('write refused');
          },
          beforeCommit: () async {
            log.add('commit');
            if (refuseCommit) throw StateError('commit refused');
          },
        ),
      ),
      profile: DatabaseProfile.native,
    );
  });

  tearDown(() => db.close());

  Future<int> localAccounts() async =>
      (await db.select(db.localAccount).get()).length;

  Future<void> insertLocalAccount() => db
      .into(db.localAccount)
      .insert(
        LocalAccountCompanion.insert(
          slot: const Value(1),
          accountId: 'a',
          createdAt: 'now',
        ),
      );

  test('a refused commit rolls the whole transaction back', () async {
    await db.localAccount.count().getSingle(); // opens the database
    log.clear();
    refuseCommit = true;

    await expectLater(
      db.transaction(insertLocalAccount),
      throwsA(isA<StateError>()),
    );

    expect(await localAccounts(), 0);
    expect(log, contains('commit'));
  });

  test('a refused write stores nothing', () async {
    await db.localAccount.count().getSingle();
    refuseWrite = true;

    await expectLater(insertLocalAccount(), throwsA(isA<StateError>()));

    expect(await localAccounts(), 0);
  });

  test('allowed work is stored, and reads are not intercepted', () async {
    await db.transaction(insertLocalAccount);
    log.clear();

    expect(await localAccounts(), 1);
    expect(log, isEmpty);
  });
}
