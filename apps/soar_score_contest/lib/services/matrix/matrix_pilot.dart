import 'package:soar_score_core/soar_score_core.dart';

/// One scoring pilot as the matrix shows them.
class MatrixPilot {
  const MatrixPilot({
    required this.participationId,
    required this.number,
    required this.name,
    required this.role,
    required this.teamId,
  });

  final Id participationId;

  /// The contest pilot number; the draw assigns it.
  final int? number;
  final String name;
  final String role;
  final Id? teamId;

  /// "12", or "–" when the contest has no pilot numbers.
  String get numberText => number?.toString() ?? '–';

  /// Whether [query] is part of the name or is the pilot number.
  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    return needle.isNotEmpty &&
        (name.toLowerCase().contains(needle) ||
            (number != null && '$number' == needle));
  }
}
