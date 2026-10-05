/// The launch height penalty for [altitude] meters.
///
/// At or below [referenceHeight] it is `altitude * minorPerMeter`. Above it,
/// it is `referenceHeight * minorPerMeter + (altitude - referenceHeight) *
/// majorPerMeter`.
double f5jHeightPenalty({
  required num altitude,
  required num referenceHeight,
  required double minorPerMeter,
  required double majorPerMeter,
}) {
  if (altitude <= referenceHeight) return altitude * minorPerMeter;
  return referenceHeight * minorPerMeter +
      (altitude - referenceHeight) * majorPerMeter;
}
