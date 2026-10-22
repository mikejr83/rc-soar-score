import 'package:soar_score_core/soar_score_core.dart';

/// Keeps contests in memory and behaves like the real repository where it
/// matters to services: a save bumps the revision and a stale save is
/// refused.
class MemoryContestRepository implements ContestRepository {
  final Map<Id, Contest> stored = {};
  final List<MutationMetadata> metadata = [];

  /// The audit events saved with contests, oldest first.
  final List<AuditEvent> audits = [];

  @override
  Future<Contest?> findById(Id id) async => stored[id];

  @override
  Future<List<Contest>> getAll() async => stored.values.toList();

  @override
  Future<Contest> save(
    Contest contest, {
    required MutationMetadata metadata,
    AuditEvent? audit,
  }) async {
    final current = stored[contest.id];
    if (current != null && current.revision != contest.revision) {
      throw StaleRevisionError(
        entityType: 'Contest',
        entityId: contest.id,
        expectedRevision: contest.revision,
        storedRevision: current.revision,
      );
    }
    this.metadata.add(metadata);
    if (audit != null) audits.add(audit);
    final next = Contest.fromJson({
      ...contest.toJson(),
      'revision': current == null ? 0 : current.revision + 1,
    });
    stored[contest.id] = next;
    return next;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

/// Configuration revisions in memory; [appendWithContest] saves the contest
/// through [contests] first, so a stale contest stores nothing.
class MemoryConfigurationRevisionRepository
    implements ContestConfigurationRevisionRepository {
  MemoryConfigurationRevisionRepository(this.contests);

  final MemoryContestRepository contests;
  final List<ContestConfigurationRevision> stored = [];

  @override
  Future<ContestConfigurationRevision?> findById(Id id) async =>
      stored.where((r) => r.id == id).firstOrNull;

  @override
  Future<List<ContestConfigurationRevision>> listForContest(
    Id contestId,
  ) async =>
      stored.where((r) => r.contestId == contestId).toList()
        ..sort((a, b) => a.revisionNumber.compareTo(b.revisionNumber));

  @override
  Future<ContestConfigurationRevision?> latestForContest(Id contestId) async =>
      (await listForContest(contestId)).lastOrNull;

  @override
  Future<ContestConfigurationRevision> append(
    ContestConfigurationRevision revision, {
    required MutationMetadata metadata,
  }) async {
    stored.add(revision);
    return revision;
  }

  @override
  Future<SavedConfiguration> appendWithContest(
    ContestConfigurationRevision revision, {
    required Contest contest,
    required MutationMetadata metadata,
  }) async {
    final savedContest = await contests.save(
      contest,
      metadata: metadata.forPart(contest.id.value),
    );
    stored.add(revision);
    return SavedConfiguration(revision: revision, contest: savedContest);
  }
}

class MemoryDisciplineProfileRepository implements DisciplineProfileRepository {
  MemoryDisciplineProfileRepository(Iterable<DisciplineProfileWithRules> all)
    : _all = {for (final p in all) p.profile.id: p};

  final Map<Id, DisciplineProfileWithRules> _all;

  @override
  Future<DisciplineProfileWithRules?> findById(Id id) async => _all[id];

  @override
  Future<List<DisciplineProfileWithRules>> listPublished() async =>
      _all.values.toList();

  @override
  Future<bool> installSystemProfile(DisciplineProfileWithRules profile) async =>
      throw UnimplementedError();
}

class MemoryLandingTableRepository implements LandingTableRepository {
  MemoryLandingTableRepository(Iterable<LandingTableWithResults> all)
    : _all = {for (final t in all) t.table.id: t};

  final Map<Id, LandingTableWithResults> _all;

  @override
  Future<LandingTableWithResults?> findById(Id id) async => _all[id];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

/// A [Repository] holding only the contracts a test supplies; the others
/// throw when used.
class FakeRepository implements Repository {
  FakeRepository({
    required this.contestRepository,
    ContestConfigurationRevisionRepository? configurationRepository,
    DisciplineProfileRepository? profileRepository,
    LandingTableRepository? landingTableRepository,
  }) : _configurations = configurationRepository,
       _profiles = profileRepository,
       _landingTables = landingTableRepository;

  @override
  final ContestRepository contestRepository;
  final ContestConfigurationRevisionRepository? _configurations;
  final DisciplineProfileRepository? _profiles;
  final LandingTableRepository? _landingTables;

  @override
  ContestConfigurationRevisionRepository
  get contestConfigurationRevisionRepository =>
      _configurations ?? (throw UnimplementedError('configurations'));

  @override
  DisciplineProfileRepository get disciplineProfileRepository =>
      _profiles ?? (throw UnimplementedError('profiles'));

  @override
  LandingTableRepository get landingTableRepository =>
      _landingTables ?? (throw UnimplementedError('landing tables'));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}
