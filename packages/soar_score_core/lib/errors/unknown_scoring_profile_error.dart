import '../enums/discipline_type.dart';

/// Thrown when no scoring profile is registered for a discipline and version.
class UnknownScoringProfileError implements Exception {
  const UnknownScoringProfileError(this.discipline, this.rulesVersion);

  final DisciplineType discipline;
  final int rulesVersion;

  @override
  String toString() =>
      'UnknownScoringProfileError: no profile for '
      '${discipline.name} rules version $rulesVersion';
}
