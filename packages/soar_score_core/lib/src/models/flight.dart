/// Base class for flight attempts across all disciplines.
///
/// Each discipline has its own scoring fields. This abstract class provides
/// the common structure while discipline-specific classes define their own
/// scoring inputs.
abstract class Flight {
  final String id;
  final String pilotId;

  Flight({
    required this.id,
    required this.pilotId,
  });
}

mixin WithLandingBonus {
  /// Landing bonus points (from configured landing table).
  int? get landingBonus;
}
