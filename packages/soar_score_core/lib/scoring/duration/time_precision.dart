/// Whether [seconds] has at most [decimals] decimal places.
bool hasAtMostDecimals(double seconds, int decimals) {
  var scale = 1.0;
  for (var i = 0; i < decimals; i++) {
    scale *= 10;
  }
  final scaled = seconds * scale;
  return (scaled - scaled.roundToDouble()).abs() <= 1e-9;
}
