import 'package:soar_score_core/soar_score_core.dart';

/// In-memory [ContestRepository] for handler tests.
///
/// It behaves like the real one where handlers depend on it: a save bumps
/// the revision and a stale save throws [StaleRevisionError]. [savedWith]
/// lists the metadata of every save, so tests can check who acted.
class StubContestRepository implements ContestRepository {
  final Map<Id, Contest> _contests = {};

  /// The metadata of every save, oldest first.
  final List<MutationMetadata> savedWith = [];

  /// The audit events saved with contests, oldest first.
  final List<AuditEvent> audits = [];

  /// Stores [contest] as it is, without a revision bump, to arrange a state
  /// the API cannot reach in one step.
  void replace(Contest contest) => _contests[contest.id] = contest;

  @override
  Future<Contest?> findById(Id id) async => _contests[id];

  @override
  Future<List<Contest>> getAll() async => _contests.values.toList();

  @override
  Future<Contest> save(
    Contest contest, {
    required MutationMetadata metadata,
    AuditEvent? audit,
  }) async {
    final current = _contests[contest.id];
    if (current != null && current.revision != contest.revision) {
      throw StaleRevisionError(
        entityType: 'Contest',
        entityId: contest.id,
        expectedRevision: contest.revision,
        storedRevision: current.revision,
      );
    }
    savedWith.add(metadata);
    if (audit != null) audits.add(audit);
    final stored = Contest.fromJson({
      ...contest.toJson(),
      'revision': current == null ? 0 : current.revision + 1,
    });
    _contests[contest.id] = stored;
    return stored;
  }

  @override
  Future<bool> delete(Id id, {required MutationMetadata metadata}) async =>
      _contests.remove(id) != null;

  @override
  Future<void> close() async {}
}
