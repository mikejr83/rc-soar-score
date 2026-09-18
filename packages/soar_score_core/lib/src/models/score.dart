/// Represents a score attempt (submission).
///
/// Scores are immutable attempts with provenance. Each submission contains
/// canonical raw components, provenance data, and is associated with a score
/// placeholder. Multiple attempts can exist for the same placeholder, forming
/// an immutable submission history. The current official selection is tracked
/// separately.
class Score {
  final String id;
  final String placeholderId;
  final Map<String, dynamic> rawComponents;
  final String? actor;
  final String? authority;
  final DateTime submissionTime;
  final String? invitationRef;
  final String? sourceDevice;
  final String clientMutationId;
  final String baseScoreRevision;
  final String configRevision;
  final String matrixRevision;
  final String disciplineRulesVersion;
  final String calculationVersion;

  Score({
    required this.id,
    required this.placeholderId,
    required this.rawComponents,
    this.actor,
    this.authority,
    required this.submissionTime,
    this.invitationRef,
    this.sourceDevice,
    required this.clientMutationId,
    required this.baseScoreRevision,
    required this.configRevision,
    required this.matrixRevision,
    required this.disciplineRulesVersion,
    required this.calculationVersion,
  });
}