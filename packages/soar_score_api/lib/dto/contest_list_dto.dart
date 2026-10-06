import 'package:soar_score_core/soar_score_core.dart';

/// Response payload of `GET /api/v1/contests`.
///
/// The contests are the shared core [Contest] model, so the client, the
/// handlers and the database cannot drift apart on field names.
class ContestListDto {
  const ContestListDto({required this.contests});

  final List<Contest> contests;

  factory ContestListDto.fromJson(Map<String, dynamic> json) => ContestListDto(
    contests: [
      for (final item in json['contests'] as List<dynamic>)
        Contest.fromJson(item as Map<String, dynamic>),
    ],
  );

  Map<String, dynamic> toJson() => {
    'contests': [for (final contest in contests) contest.toJson()],
  };
}
