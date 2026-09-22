import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  group('Id.parse', () {
    test('accepts a well-formed UUIDv7', () {
      final id = Id.parse('01957d1e-5b4a-7e58-bc31-8c5a1f9d2e40');

      expect(id.value, '01957d1e-5b4a-7e58-bc31-8c5a1f9d2e40');
      expect(id.toString(), '01957d1e-5b4a-7e58-bc31-8c5a1f9d2e40');
    });

    test('normalizes surrounding whitespace and upper-case input', () {
      final raw = '01957D1E-5B4A-7E58-BC31-8C5A1F9D2E40 ';

      expect(Id.parse(raw).value, '01957d1e-5b4a-7e58-bc31-8c5a1f9d2e40');
    });

    test('rejects malformed, non-UUID, and wrong-version input', () {
      expect(() => Id.parse('not-a-uuid'), throwsArgumentError);
      expect(
        () => Id.parse('860b59c9-e470-4abc-9a4c-b2c5d4f61a38'),
        throwsArgumentError,
      );
      expect(
        () => Id.parse('01957d1e-5b4a-5e58-bc31-8c5a1f9d2e40'),
        throwsArgumentError,
      );
      expect(() => Id.parse('01957d1e5b4a7e58bc318c5a1f9d2e40'), throwsArgumentError);
      expect(() => Id.parse(''), throwsArgumentError);
    });
  });

  group('Id.create', () {
    test('generates a parseable, lower-case UUIDv7', () {
      final id = Id.create();

      expect(id.value, id.toString());
      expect(() => Id.parse(id.value), returnsNormally);
    });

    test('generates distinct values', () {
      expect(Id.create().value, isNot(Id.create().value));
    });
  });

  group('equality and ordering', () {
    test('identical values are equal, distinct values are not', () {
      const value = '01957d1e-5b4a-7e58-bc31-8c5a1f9d2e40';
      final a = Id.parse(value);
      final b = Id.parse(value);
      final c = Id.create();

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });

    test('compareTo orders by canonical value', () {
      final a = Id.parse('01957d1e-5b4a-7e58-bc31-8c5a1f9d2e40');
      final b = Id.parse('01957d1e-5b4a-7e58-bc32-8c5a1f9d2e40');

      expect(a.compareTo(b), lessThan(0));
      expect(b.compareTo(a), greaterThan(0));
      expect(a.compareTo(a), 0);
    });
  });
}
