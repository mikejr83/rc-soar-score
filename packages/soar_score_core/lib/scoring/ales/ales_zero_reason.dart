/// A reportable reason an ALES flight scored zero.
///
/// [code] matches the `zero_reason_code` of the profile's score fields.
enum AlesZeroReason {
  motorRestart('motor_restart'),
  outOfBounds('out_of_bounds'),
  overflightOverOneMinute('overflight_gt_one_min');

  const AlesZeroReason(this.code);

  final String code;
}
