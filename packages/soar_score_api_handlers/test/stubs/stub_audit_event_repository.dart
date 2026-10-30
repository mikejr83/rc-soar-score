import 'package:soar_score_core/soar_score_core.dart';

import 'stub_configuration_repositories.dart';
import 'stub_contest_repository.dart';
import 'stub_matrix_repositories.dart';

/// Reads the audit events the stub repositories keep: the ones
/// [StubContestRepository] stored with its saves, and the ones the
/// configuration and matrix stubs stored with their appends.
class StubAuditEventRepository implements AuditEventRepository {
  StubAuditEventRepository(
    this._contests,
    this._configurations,
    this._matrixRevisions,
  );

  final StubContestRepository _contests;
  final StubConfigurationRevisionRepository _configurations;
  final StubMatrixRevisionRepository _matrixRevisions;

  @override
  Future<List<AuditEvent>> listForContest(
    Id contestId, {
    AuditAction? action,
    int? limit,
  }) async {
    final events = [
      for (final event in [
        ..._contests.audits,
        ..._configurations.audits,
        ..._matrixRevisions.audits,
      ])
        if (event.contestId == contestId &&
            (action == null || event.action == action))
          event,
    ]..sort((a, b) {
      final byTime = b.serverTimestamp.compareTo(a.serverTimestamp);
      return byTime != 0 ? byTime : b.id.value.compareTo(a.id.value);
    });
    return limit == null ? events : events.take(limit).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}
