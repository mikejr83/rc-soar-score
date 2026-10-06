import 'package:soar_score_core/soar_score_core.dart' as core;

/// Inserts a few sample contests so a fresh offline install has something to
/// list.
///
/// Development only: the native app runs it when built with
/// `--dart-define=SOAR_SCORE_SEED_DEMO=true`, never in a release build. It is
/// a stand-in until contests can be created in the app (#113). The contests
/// belong to the installation's Local account, which is also the actor of the
/// seeding mutations.
class DemoContestSeeder {
  DemoContestSeeder(
    this._contests, {
    required core.Id localAccountId,
    DateTime Function()? clock,
  }) : _localAccountId = localAccountId,
       _clock = clock ?? DateTime.now;

  final core.ContestRepository _contests;
  final core.Id _localAccountId;
  final DateTime Function() _clock;

  /// Saves the sample contests if no contest exists yet, and returns how many
  /// it saved. A second run, or a run on a database that already holds
  /// contests, saves nothing.
  Future<int> seed() async {
    if ((await _contests.getAll()).isNotEmpty) {
      return 0;
    }
    final now = _clock().toUtc();
    final samples = _samples(now);
    for (final contest in samples) {
      await _contests.save(
        contest,
        metadata: core.MutationMetadata(
          clientMutationId: 'demo-seed/${contest.id}',
          authority: core.Authority.system,
          clientTime: now,
          actorId: _localAccountId,
        ),
      );
    }
    return samples.length;
  }

  List<core.Contest> _samples(DateTime now) => [
    core.Contest(
      ownerAccountId: _localAccountId,
      id: core.Id.parse('019c0000-0000-7000-8000-00000000d001'),
      name: 'Front Range F5J Open',
      startDateTime: DateTime.utc(2026, 10, 17, 14),
      endDateTime: DateTime.utc(2026, 10, 18, 22),
      timezone: 'America/Denver',
      city: 'Longmont',
      state: 'CO',
      country: 'US',
      lifecycleState: core.LifecycleState.ready,
      createdAt: now,
      updatedAt: now,
    ),
    core.Contest(
      ownerAccountId: _localAccountId,
      id: core.Id.parse('019c0000-0000-7000-8000-00000000d002'),
      name: 'Club Thermal Fun Fly',
      startDateTime: DateTime.utc(2026, 11, 7, 16),
      endDateTime: DateTime.utc(2026, 11, 7, 23),
      timezone: 'America/Denver',
      createdAt: now,
      updatedAt: now,
    ),
    core.Contest(
      ownerAccountId: _localAccountId,
      id: core.Id.parse('019c0000-0000-7000-8000-00000000d003'),
      name: 'Autumn ALES Classic',
      startDateTime: DateTime.utc(2026, 9, 12, 15),
      endDateTime: DateTime.utc(2026, 9, 13, 22),
      timezone: 'America/Denver',
      lifecycleState: core.LifecycleState.completed,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}
