import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/widgets/entry/score_entry_form.dart';

void main() {
  test('a mutation id names the pilot and round and differs per attempt', () {
    final a = newEntryMutationId('p1', 2);
    final b = newEntryMutationId('p1', 2, random: Random(1));
    expect(a, startsWith('entry-p1-2-'));
    expect(b, startsWith('entry-p1-2-'));
    expect(a, isNot(b));
  });
}
