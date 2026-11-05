/// Turns what the pilot typed into the F5J score components the API takes.
/// The keys and the zeroing rules match the director's score entry in the
/// contest app, so both screens store the same thing.
Map<String, Object?> buildF5jComponents({
  required double? seconds,
  required int? height,
  required String? landingId,
  required bool lateLanding,
  required bool motorRestart,
  required bool outOfBounds,
  required bool noAltitude,
  required int? penalty,
}) {
  final out = <String, Object?>{};
  if (noAltitude) {
    out['no_altitude_recorded'] = true;
  } else if (motorRestart) {
    out['motor_restart'] = true;
  } else if (outOfBounds) {
    out['out_of_bounds'] = true;
  } else {
    if (seconds != null) {
      out['time_flown'] = seconds == seconds.roundToDouble()
          ? seconds.toInt()
          : seconds;
    }
    if (height != null) out['launch_height'] = height;
    if (landingId != null && !lateLanding) out['landing'] = landingId;
    if (lateLanding) out['late_landing'] = true;
  }
  if (penalty != null && penalty > 0) out['flight_penalty'] = penalty;
  return out;
}
