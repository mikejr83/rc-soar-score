import 'package:soar_score_sync/src/outbox_order.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  test('keeps the stored order when nothing depends on anything', () {
    final pending = [mutation(1), mutation(2), mutation(3)];

    expect(inDependencyOrder(pending).map((m) => m.clientMutationId), [
      'm-1',
      'm-2',
      'm-3',
    ]);
  });

  test('puts a dependency before the mutation that uses it', () {
    final matrix = mutation(2);
    final score = mutation(1, dependsOn: matrix.id);

    final ordered = inDependencyOrder([score, matrix]);

    expect(ordered.map((m) => m.clientMutationId), ['m-2', 'm-1']);
  });

  test('orders a chain of dependencies', () {
    final a = mutation(1);
    final b = mutation(2, dependsOn: a.id);
    final c = mutation(3, dependsOn: b.id);

    expect(inDependencyOrder([c, b, a]).map((m) => m.clientMutationId), [
      'm-1',
      'm-2',
      'm-3',
    ]);
  });

  test('a dependency already acknowledged puts no constraint', () {
    final score = mutation(1, dependsOn: idN(9999));

    expect(inDependencyOrder([score]), [score]);
  });

  test('a cycle keeps every mutation once', () {
    final a = mutation(1, dependsOn: idN(1002));
    final b = mutation(2, dependsOn: a.id);

    expect(inDependencyOrder([a, b]), hasLength(2));
  });
}
