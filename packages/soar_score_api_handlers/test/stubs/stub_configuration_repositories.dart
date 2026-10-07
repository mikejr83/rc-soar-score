import 'package:soar_score_core/soar_score_core.dart';

import 'stub_contest_repository.dart';

/// Configuration revisions in memory. [appendWithContest] saves the contest
/// through [contests] first, so a stale contest stores nothing.
class StubConfigurationRevisionRepository
    implements ContestConfigurationRevisionRepository {
  StubConfigurationRevisionRepository(this.contests);

  final StubContestRepository contests;
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

/// Serves the system discipline profiles.
class StubDisciplineProfileRepository implements DisciplineProfileRepository {
  final Map<Id, DisciplineProfileWithRules> _profiles = {
    for (final profile in SystemDisciplineProfiles.all)
      profile.profile.id: profile,
  };

  @override
  Future<DisciplineProfileWithRules?> findById(Id id) async => _profiles[id];

  @override
  Future<List<DisciplineProfileWithRules>> listPublished() async =>
      _profiles.values.toList();

  @override
  Future<bool> installSystemProfile(DisciplineProfileWithRules profile) async =>
      throw UnimplementedError();
}

/// Serves the system landing tables.
class StubLandingTableRepository implements LandingTableRepository {
  final Map<Id, LandingTableWithResults> _tables = {
    for (final table in SystemLandingTables.all) table.table.id: table,
  };

  /// The tables a test says are used by a configuration.
  final Set<Id> inUse = {};

  /// The metadata of every create and delete, in order.
  final List<MutationMetadata> writtenWith = [];

  @override
  Future<LandingTableWithResults?> findById(Id id) async => _tables[id];

  @override
  Future<List<LandingTableWithResults>> listVisibleTo({
    Id? ownerAccountId,
  }) async => [
    for (final table in _tables.values)
      if (table.table.isSystem || table.table.ownerAccountId == ownerAccountId)
        table,
  ];

  @override
  Future<LandingTableWithResults> create(
    LandingTableWithResults table, {
    required MutationMetadata metadata,
  }) async {
    writtenWith.add(metadata);
    return _tables[table.table.id] = table;
  }

  @override
  Future<bool> isInUse(Id id) async => inUse.contains(id);

  @override
  Future<bool> delete(Id id, {required MutationMetadata metadata}) async {
    writtenWith.add(metadata);
    return _tables.remove(id) != null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}
