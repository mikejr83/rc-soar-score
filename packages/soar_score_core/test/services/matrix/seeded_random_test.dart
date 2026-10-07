import 'package:soar_score_core/services/services.dart';
import 'package:test/test.dart';

void main() {
  group('SeededRandom', () {
    test('the same seed gives the same sequence', () {
      final a = SeededRandom(42);
      final b = SeededRandom(42);
      expect(
        [for (var i = 0; i < 20; i++) a.nextUint32()],
        [for (var i = 0; i < 20; i++) b.nextUint32()],
      );
    });

    test('different seeds give different sequences', () {
      expect(SeededRandom(1).nextUint32(), isNot(SeededRandom(2).nextUint32()));
    });

    // Reference values from the published JavaScript Mulberry32, so every
    // platform (the web included) deals the same draw from the same seed.
    test('matches the reference Mulberry32 sequence', () {
      List<int> take(int seed) {
        final random = SeededRandom(seed);
        return [for (var i = 0; i < 4; i++) random.nextUint32()];
      }

      expect(take(1), [0xA087EAF3, 0x00B349C9, 0x8706C4EB, 0xFB2627FD]);
      expect(take(0xFFFFFFFF), [
        0xE57BF3D3,
        0x3081A5A4,
        0xB7350390,
        0xF1ADE904,
      ]);
      expect(take(123456789), [0x41FE92FE, 0xF8848567, 0xC90B41BA, 0x34C733B0]);
    });

    test('nextInt stays within range', () {
      final random = SeededRandom(7);
      for (var i = 0; i < 1000; i++) {
        final value = random.nextInt(6);
        expect(value, inInclusiveRange(0, 5));
      }
      expect(() => random.nextInt(0), throwsArgumentError);
    });

    test('shuffle keeps the same items', () {
      final items = [for (var i = 0; i < 30; i++) i];
      final shuffled = SeededRandom(3).shuffle([...items]);
      expect(shuffled.toSet(), items.toSet());
      expect(shuffled, isNot(items));
    });
  });
}
