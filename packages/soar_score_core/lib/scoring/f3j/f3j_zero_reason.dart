/// A reportable reason a flight scored zero.
///
/// [code] matches the `zero_reason_code` of the profile's score fields.
enum F3jZeroReason {
  outOfBounds('out_of_bounds');

  const F3jZeroReason(this.code);

  final String code;
}
