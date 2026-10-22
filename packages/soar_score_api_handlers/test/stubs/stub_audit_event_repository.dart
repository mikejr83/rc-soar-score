import 'package:soar_score_core/soar_score_core.dart';

import 'stub_contest_repository.dart';

/// Reads the audit events [StubContestRepository] kept with its saves.
class StubAuditEventRepository implements AuditEventRepository {
  StubAuditEventRepository(this._contests);

  final StubContestRepository _contests;

  @override
  Future<List<AuditEvent>> listForContest(
    Id contestId, {
    AuditAction? action,
    int? limit,
  }) async {
    final events = [
      for (final event in _contests.audits.reversed)
        if (event.contestId == contestId &&
            (action == null || event.action == action))
          event,
    ];
    return limit == null ? events : events.take(limit).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}
