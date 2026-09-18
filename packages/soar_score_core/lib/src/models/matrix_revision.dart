/// Represents a matrix revision for a contest.
///
/// A matrix contains rounds, groups, and assignments. Each draw creates a
/// new matrix revision that is never overwritten.
class MatrixRevision {
  final String id;
  final String contestId;
  final int revision;
  final Map<String, dynamic> drawConfiguration;
  final List<String> participatingPilotIds;
  final DateTime createdAt;
  final String createdBy;
  final String? reason;
  final bool finalized;

  MatrixRevision({
    required this.id,
    required this.contestId,
    required this.revision,
    required this.drawConfiguration,
    required this.participatingPilotIds,
    required this.createdAt,
    required this.createdBy,
    this.reason,
    this.finalized = false,
  });
}