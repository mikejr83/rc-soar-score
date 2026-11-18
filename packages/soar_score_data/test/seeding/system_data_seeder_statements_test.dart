import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

/// Counts the statements a database runs.
class _Counter extends QueryInterceptor {
  final statements = <String>[];

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor e,
    String s,
    List<Object?> a,
  ) {
    statements.add(s);
    return super.runSelect(e, s, a);
  }

  @override
  Future<int> runInsert(QueryExecutor e, String s, List<Object?> a) {
    statements.add(s);
    return super.runInsert(e, s, a);
  }

  @override
  Future<int> runUpdate(QueryExecutor e, String s, List<Object?> a) {
    statements.add(s);
    return super.runUpdate(e, s, a);
  }

  @override
  Future<void> runCustom(QueryExecutor e, String s, List<Object?> a) {
    statements.add(s);
    return super.runCustom(e, s, a);
  }
}

// First launch used to take 291 statements (one upsert per row). Rows now go
// in multi-row inserts (48 now), so the count follows the number of tables and shipped
// entities, not rows. A count, never a time. Raise it only with a reason.
const _firstRunBudget = 50;

void main() {
  test('first-run system seed stays within its statement budget', () async {
    final counter = _Counter();
    final db = SoarScoreDatabase(
      NativeDatabase.memory().interceptWith(counter),
      profile: DatabaseProfile.native,
    );
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get(); // creates the schema
    counter.statements.clear();

    await SystemDataSeeder(db).seed();
    final first = counter.statements.length;
    counter.statements.clear();
    await SystemDataSeeder(db).seed();
    final second = counter.statements.length;

    expect(
      first,
      lessThanOrEqualTo(_firstRunBudget),
      reason: counter.statements.join('\n'),
    );
    // Up to date: only the cursor read.
    expect(second, lessThanOrEqualTo(2));
  });
}
