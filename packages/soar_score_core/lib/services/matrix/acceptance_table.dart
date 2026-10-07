/// The annealing acceptance test in whole numbers, so every platform (web,
/// desktop, server) accepts exactly the same moves.
///
/// `exp` is only approximated, and not identically, by different runtimes.
/// This table holds `exp(-k / 16)` in 16-bit fixed point for `k` up to the
/// point where it is about 8 parts in 65,536, built with integer arithmetic
/// only (`matrix-draw.md` section 4.1).
class AcceptanceTable {
  AcceptanceTable._(this._values);

  /// The one table, built once.
  static final AcceptanceTable instance = AcceptanceTable._(_build());

  /// `exp(-1 / 16)` in 16-bit fixed point.
  static const int _step = 61565;

  static List<int> _build() {
    final values = <int>[65536];
    // Rounding to 16 bits makes small values stick (near 8), so the table
    // ends before that: a move less than 8 chances in 65,536 is never
    // accepted.
    while (values.last > 8) {
      values.add((values.last * _step + 32768) ~/ 65536);
    }
    return values;
  }

  final List<int> _values;

  /// How many entries the table has.
  int get length => _values.length;

  /// The probability, in 65,536ths, of accepting a move that raises the cost
  /// by [delta] at the temperature [temperature256] (in 256ths). Zero when
  /// the move is too bad to accept.
  int probability(int delta, int temperature256) {
    if (delta <= 0) {
      return 65536;
    }
    final index = delta * 16 * 256 ~/ temperature256;
    return index < _values.length ? _values[index] : 0;
  }
}
