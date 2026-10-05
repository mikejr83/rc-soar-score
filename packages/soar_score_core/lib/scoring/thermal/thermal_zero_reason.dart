/// A reportable reason a Thermal flight scored zero.
///
/// [code] matches the `zero_reason_code` of the profile's score fields.
enum ThermalZeroReason {
  outOfBounds('out_of_bounds'),
  overflightOverOneMinute('overflight_gt_one_min');

  const ThermalZeroReason(this.code);

  final String code;
}
