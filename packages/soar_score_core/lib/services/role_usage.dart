import '../models/id.dart';

/// One contest that uses a role, and how many of its participants have it.
class RoleUsage {
  const RoleUsage({
    required this.contestId,
    required this.contestName,
    required this.participantCount,
  });

  factory RoleUsage.fromJson(Map<String, dynamic> json) => RoleUsage(
    contestId: Id.parse(json['contest_id'] as String),
    contestName: json['contest_name'] as String,
    participantCount: json['participant_count'] as int,
  );

  final Id contestId;
  final String contestName;
  final int participantCount;

  Map<String, dynamic> toJson() => {
    'contest_id': contestId.value,
    'contest_name': contestName,
    'participant_count': participantCount,
  };
}
