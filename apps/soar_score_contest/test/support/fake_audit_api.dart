import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'matrix_test_support.dart';

Id _eventId(int n) =>
    Id.parse('019c0000-0000-7000-8000-0000000f${n.toString().padLeft(4, '0')}');

/// A successful audit event at [minute] minutes after the contest day began.
AuditEvent auditEvent(
  int n,
  AuditAction action, {
  String? reason,
  Id? actor,
  Authority authority = Authority.director,
  int? minute,
}) => AuditEvent(
  id: _eventId(n),
  entityType: 'Contest',
  entityId: contestId,
  contestId: contestId,
  action: action,
  actorId: actor,
  authority: authority,
  serverTimestamp: DateTime.utc(
    2026,
    10,
    18,
    9,
  ).add(Duration(minutes: minute ?? n)),
  reason: reason,
);

/// An [ApiClient] over a fake server that holds [events] (any order) and
/// serves the contest and its `audit-events` route with `action`, `limit` and
/// `offset`. [requests] records the audit queries; [failAudit] makes the audit
/// route answer 503.
class FakeAuditApi {
  FakeAuditApi(this.events);

  final List<AuditEvent> events;
  final List<Map<String, String>> requests = [];
  bool failAudit = false;
  bool missingContest = false;

  /// Makes the audit route answer with this status (and no events).
  int? auditStatus;

  /// Makes every request fail as if the network were down.
  bool networkDown = false;

  /// Makes the audit route fail once it has answered this many reads.
  int? failAfterReads;

  late final ApiClient client = ApiClient(
    baseUrl: Uri.parse('http://fake.test'),
    httpClient: MockClient(_answer),
  );

  Future<http.Response> _answer(http.Request request) async {
    if (networkDown) {
      throw http.ClientException('network down', request.url);
    }
    final headers = {'content-type': 'application/json'};
    if (missingContest) {
      return http.Response(
        '{"error":{"code":"not_found","message":"No such contest","requestId":null}}',
        404,
        headers: headers,
      );
    }
    if (request.url.path.endsWith('/audit-events')) {
      requests.add(request.url.queryParameters);
      final status = auditStatus;
      if (status != null) {
        return http.Response(
          '{"error":{"code":"x","message":"m","requestId":null}}',
          status,
          headers: headers,
        );
      }
      final after = failAfterReads;
      if (failAudit || (after != null && requests.length > after)) {
        return http.Response('down', 503);
      }
      final query = request.url.queryParameters;
      final action = query['action'];
      final newestFirst = [
        for (final event in events)
          if (action == null || event.action.text == action) event,
      ]..sort((a, b) => b.serverTimestamp.compareTo(a.serverTimestamp));
      final offset = int.parse(query['offset'] ?? '0');
      final limit = int.parse(query['limit'] ?? '1000');
      return http.Response(
        jsonEncode({
          'audit_events': [
            for (final event in newestFirst.skip(offset).take(limit))
              AuditEventDto.fromEvent(event).toJson(),
          ],
        }),
        200,
        headers: headers,
      );
    }
    return http.Response(
      jsonEncode(matrixContest().toJson()),
      200,
      headers: headers,
    );
  }
}
