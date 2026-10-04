import 'package:soar_score_core/soar_score_core.dart';

Id id(int n) =>
    Id.parse('019c0000-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}');

final DateTime start = DateTime.utc(2026, 10, 17, 14);
final DateTime end = DateTime.utc(2026, 10, 18, 22);

Contest makeContest({
  String name = 'Front Range ALES Open',
  DateTime? startDateTime,
  DateTime? endDateTime,
  String timezone = 'America/Denver',
  LifecycleState lifecycleState = LifecycleState.created,
  ScoringAccess scoringAccess = ScoringAccess.closed,
  AdminLock adminLock = AdminLock.unlocked,
  int? hiddenThrough,
  DateTime? hiddenAt,
  bool localArchive = false,
  int revision = 0,
}) => Contest(
  id: id(0x10),
  name: name,
  startDateTime: startDateTime ?? start,
  endDateTime: endDateTime ?? end,
  timezone: timezone,
  ownerAccountId: id(1),
  lifecycleState: lifecycleState,
  scoringAccess: scoringAccess,
  adminLock: adminLock,
  resultsHiddenThroughRound: hiddenThrough,
  resultsHiddenAt: hiddenAt,
  localArchive: localArchive,
  createdAt: DateTime.utc(2026, 9),
  updatedAt: DateTime.utc(2026, 9),
  revision: revision,
);

ContestConfig makeConfig() => ContestConfig(
  core: {
    'teams_enabled': true,
    'team_pilot_count': 2,
    'group_score_mode': 'Time',
    'drop_after_rounds': [4],
  },
  discipline: {'target_time': 600, 'points_per_second': 1.0},
);
