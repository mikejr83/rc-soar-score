/// Represents a calculated score result.
///
/// Calculation results are derived records that store the outcome of the
/// scoring pipeline with exact input revisions and calculation metadata.
class CalculationResult {
  final String id;
  final String placeholderId;
  final String attemptId;
  final double disciplineRawScore;
  final double groupScore;
  final double contestTotal;
  final int? droppedRoundDecision;
  final int? ranking;
  final double? teamTotal;
  final String configRevision;
  final String matrixRevision;
  final String disciplineRulesVersion;
  final String calculationVersion;
  final DateTime calculatedAt;

  CalculationResult({
    required this.id,
    required this.placeholderId,
    required this.attemptId,
    required this.disciplineRawScore,
    required this.groupScore,
    required this.contestTotal,
    this.droppedRoundDecision,
    this.ranking,
    this.teamTotal,
    required this.configRevision,
    required this.matrixRevision,
    required this.disciplineRulesVersion,
    required this.calculationVersion,
    required this.calculatedAt,
  });
}