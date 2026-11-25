import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/session/contest_open_gate.dart';

void main() {
  test(
    'closing waits for an open already sent, and refuses new ones',
    () async {
      final gate = ContestOpenGate();
      final answer = Completer<String>();
      final sent = gate.run(() => answer.future);

      var settled = false;
      final closing = gate.closeAndSettle().then((_) => settled = true);
      await Future<void>.delayed(Duration.zero);
      expect(settled, isFalse, reason: 'the open has not answered yet');
      expect(await gate.run(() async => 'late'), isNull);

      answer.complete('opened');
      await closing;
      expect(await sent, 'opened');
      expect(settled, isTrue);
    },
  );

  test('a failed open still lets the close finish', () async {
    final gate = ContestOpenGate();
    final answer = Completer<String>();
    final sent = gate.run(() => answer.future);
    final closing = gate.closeAndSettle();

    answer.completeError(StateError('offline'));

    await closing;
    await expectLater(sent, throwsStateError);
  });

  test('reopening accepts opens again', () async {
    final gate = ContestOpenGate();
    await gate.closeAndSettle();
    expect(gate.isClosed, isTrue);
    gate.reopen();
    expect(await gate.run(() async => 1), 1);
  });

  test('a second sign-out joins the first and the gate reopens once', () async {
    final gate = ContestOpenGate();
    final teardown = Completer<void>();
    var runs = 0;
    final first = gate.signOut(() async {
      runs++;
      await teardown.future;
    });
    final second = gate.signOut(() async => runs++);
    await Future<void>.delayed(Duration.zero);
    expect(gate.isClosed, isTrue);
    expect(runs, 1, reason: 'the second call did not start a teardown');

    teardown.completeError(StateError('failed'));
    await expectLater(first, throwsStateError);
    await expectLater(second, throwsStateError);
    expect(gate.isClosed, isFalse);
    expect(gate.isSigningOut, isFalse);

    await gate.signOut(() async => runs++);
    expect(runs, 2, reason: 'a later sign-out starts afresh');
  });
}
