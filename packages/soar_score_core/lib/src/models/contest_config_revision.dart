/// Represents a contest configuration revision.
///
/// Contest configuration is revisioned. Each change that affects the matrix
/// or calculation creates a new revision.
class ContestConfigRevision {
  final String id;
  final String contestId;
  final int revision;
  final String disciplineId;
  final String rulesVersion;
  final Map<String, dynamic> overrides;
  final DateTime createdAt;
  final String createdBy;

  ContestConfigRevision({
    required this.id,
    required this.contestId,
    required this.revision,
    required this.disciplineId,
    required this.rulesVersion,
    required this.overrides,
    required this.createdAt,
    required this.createdBy,
  });
}