/// Sealed hierarchy describing all ways a flight attempt can score zero.
///
/// Each discipline has a subset of these reasons applicable to it. Using
/// a sealed hierarchy (rather than a free-form string) provides type safety
/// and allows the scoring engine to switch on the reason.
sealed class ZeroReason {
  const ZeroReason();

  /// Human-readable label for UI display.
  String get label;

  /// Longer description for reports or tooltips.
  String get description;
}

/// The model landed more than 75m from the pilot's landing marker.
///
/// Applicable to: F3J, ALES, F5J, Thermal Duration.
class OutOfBoundsLanding extends ZeroReason {
  const OutOfBoundsLanding();

  @override
  String get label => 'Out of bounds landing';

  @override
  String get description =>
      'Landed more than 75m from the landing marker.';
}

/// The model had not landed after one minute past the target/working time.
///
/// Applicable to: ALES, F5J, Thermal Duration.
/// (F3J uses a 30-point late-landing penalty instead.)
class OverFlightOverOneMinute extends ZeroReason {
  const OverFlightOverOneMinute();

  @override
  String get label => 'Over-flight >1 minute';

  @override
  String get description =>
      'Model had not landed after one minute past the target/working time.';
}

/// The pilot restarted the motor during the flight.
///
/// Applicable to: ALES, F5J (when motor restarts are allowed).
class MotorRestart extends ZeroReason {
  const MotorRestart();

  @override
  String get label => 'Motor restart';

  @override
  String get description =>
      'Pilot restarted the motor during the flight.';
}