import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  group('Contest', () {
    test('holds the example fields given to it', () {
      final id = Id.create();
      final startedAt = DateTime.utc(2026, 9, 26, 9, 30);

      final contest = Contest(
        id: id,
        name: '  Autumn Soaring Classic ',
        startedAt: startedAt,
      );

      expect(contest.id, id);
      expect(contest.name, 'Autumn Soaring Classic');
      expect(contest.startedAt, startedAt);
    });

    test('stores startedAt in UTC even when given a local time', () {
      final contest = Contest(
        id: Id.create(),
        name: 'Local Time Contest',
        startedAt: DateTime(2026, 9, 26, 9, 30),
      );

      expect(contest.startedAt.isUtc, isTrue);
    });

    test('rejects a blank name', () {
      expect(
        () => Contest(id: Id.create(), name: '   ', startedAt: DateTime.utc(2026)),
        throwsArgumentError,
      );
    });

    test('is equal to another instance with the same fields', () {
      final id = Id.create();
      final startedAt = DateTime.utc(2026, 9, 26, 9, 30);
      final a = Contest(id: id, name: 'Classic', startedAt: startedAt);
      final b = Contest(id: Id.parse(id.value), name: 'Classic', startedAt: startedAt);
      final other = Contest(id: Id.create(), name: 'Classic', startedAt: startedAt);

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == other, isFalse);
    });

    test('toString summarizes the identity and fields', () {
      final id = Id.create();
      final contest = Contest(id: id, name: 'Classic', startedAt: DateTime.utc(2026));

      expect(contest.toString(), contains(id.value));
      expect(contest.toString(), contains('Classic'));
    });
  });
}
