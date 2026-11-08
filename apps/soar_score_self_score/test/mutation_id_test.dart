import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/widgets/entry/score_entry_form.dart';

/// Records the bound it is asked for and answers with the largest value.
class _RecordingRandom implements Random {
  int? max;

  @override
  int nextInt(int max) {
    this.max = max;
    return max - 1;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

void main() {
  test('a mutation id names the pilot and round and differs per attempt', () {
    final a = newEntryMutationId('p1', 2);
    final b = newEntryMutationId('p1', 2, random: Random(1));
    expect(a, startsWith('entry-p1-2-'));
    expect(b, startsWith('entry-p1-2-'));
    expect(a, isNot(b));
  });

  // `1 << 32` is 0 in a browser build, which made Random.nextInt throw there.
  test('the random bound is 2^32 and its largest value is used', () {
    final random = _RecordingRandom();
    final id = newEntryMutationId('p1', 2, random: random);
    expect(random.max, 4294967296);
    expect(id, endsWith('-4294967295'));
  });
}
