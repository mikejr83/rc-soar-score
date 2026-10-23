/// One result from a contest's landing table: the object the entry form
/// stores by [id] and the read-only view shows as [label] and [points].
class LandingResult {
  const LandingResult({
    required this.id,
    required this.label,
    required this.points,
    this.description,
  });

  final String id;
  final String label;
  final int points;

  /// Optional second line, such as the distance band.
  final String? description;
}
