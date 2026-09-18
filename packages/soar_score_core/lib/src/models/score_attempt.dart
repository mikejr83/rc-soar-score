/// Represents a score attempt (submission).
///
/// Score attempts are immutable and contain provenance data. Multiple attempts
/// can exist for the same score placeholder, forming an immutable history.
class ScoreAttempt {
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

  ScoreAttempt({
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