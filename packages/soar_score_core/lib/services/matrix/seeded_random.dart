/// A deterministic 32-bit pseudo-random generator (Mulberry32).
///
/// The same seed gives the same sequence on every platform, including the
/// web, where integers are doubles: every product is computed in 16-bit
/// halves so no intermediate value passes 2^53. Used by the matrix draw so
/// a draw can be reproduced from its seed.
class SeededRandom {
  SeededRandom(int seed) : _state = seed & _mask;

  static const int _mask = 0xFFFFFFFF;

  int _state;

  /// The next unsigned 32-bit value.
  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & _mask;
    var t = _state;
    t = _imul(t ^ (t >> 15), t | 1);
    t = (t ^ ((t + _imul(t ^ (t >> 7), t | 61)) & _mask)) & _mask;
    return (t ^ (t >> 14)) & _mask;
  }

  /// A value in `[0, max)`.
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'must be positive');
    }
    return (nextUint32() * max) ~/ 0x100000000;
  }

  /// Shuffles [items] in place (Fisher-Yates) and returns it.
  List<T> shuffle<T>(List<T> items) {
    for (var i = items.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final swap = items[i];
      items[i] = items[j];
      items[j] = swap;
    }
    return items;
  }

  /// `a * b` modulo 2^32, for unsigned 32-bit [a] and [b].
  static int _imul(int a, int b) =>
      (((a & 0xFFFF) * b) + ((((a >> 16) * b) & 0xFFFF) << 16)) & _mask;
}
