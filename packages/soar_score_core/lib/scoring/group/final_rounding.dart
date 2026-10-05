import '../../enums/rounding_mode.dart';

/// Rounds half away from zero, or truncates, to [decimals] places.
///
/// A tolerance of 1e-9 absorbs binary floating-point error, so 2.675 rounds
/// to 2.68 and a computed 2.9999999999 truncates to 3. Apply it once, to the
/// final group score only.
double applyFinalRounding(double value, RoundingMode mode, int decimals) {
  var scale = 1.0;
  for (var i = 0; i < decimals; i++) {
    scale *= 10;
  }
  final scaled = value.abs() * scale;
  final whole = switch (mode) {
    RoundingMode.round => (scaled + 0.5 + 1e-9).floorToDouble(),
    RoundingMode.truncate => (scaled + 1e-9).floorToDouble(),
  };
  final result = whole / scale;
  return value < 0 ? -result : result;
}
