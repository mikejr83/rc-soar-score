import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/matrix/draw_form_check.dart';

DrawFormCheck _check({
  String rounds = '6',
  String groups = '3',
  int pilots = 20,
  int minimum = 0,
  bool submitted = false,
}) => DrawFormCheck.evaluate(
  roundsText: rounds,
  groupsText: groups,
  pilots: pilots,
  minimumGroups: minimum,
  submitted: submitted,
);

void main() {
  group('splitGroups', () {
    test('differs by at most one pilot, larger groups first', () {
      expect(DrawFormCheck.splitGroups(20, 3), [7, 7, 6]);
      expect(DrawFormCheck.splitGroups(6, 2), [3, 3]);
      expect(DrawFormCheck.splitGroups(5, 5), [1, 1, 1, 1, 1]);
    });
  });

  group('DrawFormCheck', () {
    test('accepts whole numbers and shows the group sizes', () {
      final check = _check();
      expect(check.valid, isTrue);
      expect(check.sizes, [7, 7, 6]);
      expect(check.groupsWarning, isNull);
    });

    test('does not scold an empty field before the draw is asked for', () {
      final check = _check(rounds: '', groups: '');
      expect(check.roundsError, isNull);
      expect(check.groupsError, isNull);
      expect(check.valid, isFalse);
      final submitted = _check(rounds: '', groups: '', submitted: true);
      expect(submitted.roundsError, 'Enter the number of rounds.');
      expect(submitted.groupsError, 'Enter the number of groups per round.');
    });

    test('rejects zero and non-numbers', () {
      expect(_check(rounds: '0').roundsError, isNotNull);
      expect(_check(groups: '2.5').groupsError, isNotNull);
      expect(_check(rounds: 'x').valid, isFalse);
    });

    test('team protection sets a minimum number of groups', () {
      final check = _check(groups: '2', minimum: 3);
      expect(
        check.groupsError,
        'At least 3 groups are needed with team protection on.',
      );
      expect(_check(groups: '3', minimum: 3).valid, isTrue);
    });

    test('more groups than pilots is an error', () {
      final check = _check(groups: '21');
      expect(check.groupsError, 'There are only 20 scoring pilots.');
      expect(check.sizes, isEmpty);
    });

    test('a group with one pilot warns but does not block', () {
      final check = _check(groups: '11', pilots: 21);
      expect(check.groupsWarning, contains('Group K would have 1 pilot'));
      expect(check.valid, isTrue);
    });
  });
}
