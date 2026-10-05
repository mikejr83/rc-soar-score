/// A reportable reason a flight scored zero.
///
/// [code] matches the `zero_reason_code` of the profile's score fields.
enum F5jZeroReason {
  motorRestart('motor_restart'),
  outOfBounds('out_of_bounds'),
  noAltitudeRecorded('no_altitude_recorded');

  const F5jZeroReason(this.code);

  final String code;
}
