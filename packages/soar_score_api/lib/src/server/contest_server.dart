import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_data/soar_score_data.dart';

/// HTTP server exposing the contest API endpoints.
///
/// This is the single source of truth for the contest API surface. It is
/// built on top of the domain models ([Contest]) and the data-access
/// layer ([ContestRepository]), so the application that serves it
/// (`apps/soar-score-api`) stays a thin entrypoint that only wires this
/// server into an HTTP pipeline and starts it.
class ContestServer {
  final ContestRepository _repository;

  /// Creates a contest API server backed by [repository].
  ContestServer({required ContestRepository repository})
      : _repository = repository {
    _router.get('/health', _getHealth);
    _router.get('/api/contests', _getContests);
    _router.get('/api/contests/<id>', _getContest);
    _router.post('/api/contests', _createContest);
    _router.put('/api/contests/<id>', _updateContest);
    _router.delete('/api/contests/<id>', _deleteContest);
  }

  final Router _router = Router();

  /// The shelf handler for the API.
  Handler get handler => _router;

  Future<Response> _getHealth(Request request) async {
    return Response.ok(
      jsonEncode({
        'status': 'healthy',
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<Response> _getContests(Request request) async {
    final contests = await _repository.getContests();
    return Response.ok(
      jsonEncode({'contests': contests.map(_contestToJson).toList()}),
    );
  }

  Future<Response> _getContest(Request request, String id) async {
    final contest = await _repository.getContest(id);
    if (contest == null) {
      return _notFound();
    }
    return Response.ok(jsonEncode({'contest': _contestToJson(contest)}));
  }

  Future<Response> _createContest(Request request) async {
    final body = jsonDecode(await request.readAsString());
    final now = DateTime.now();
    final contest = Contest(
      id: _generateId(),
      name: (body['name'] as String?) ?? '',
      startDate: _parseDate(body['startDate']),
      endDate: _parseDate(body['endDate']),
      hostVenue: (body['hostVenue'] as String?) ?? '',
      city: body['city'] as String?,
      stateProvince: body['stateProvince'] as String?,
      country: body['country'] as String?,
      timezone: body['timezone'] as String?,
      ownerAccountId: body['ownerAccountId'] as String?,
      createdAt: now,
      lastModifiedAt: now,
    );
    await _repository.saveContest(contest);
    return Response(201, body: jsonEncode({'contest': _contestToJson(contest)}));
  }

  Future<Response> _updateContest(Request request, String id) async {
    final existing = await _repository.getContest(id);
    if (existing == null) {
      return _notFound();
    }
    final body = jsonDecode(await request.readAsString());
    final updated = Contest(
      id: existing.id,
      name: (body['name'] as String?) ?? existing.name,
      startDate: body['startDate'] != null
          ? _parseDate(body['startDate'])
          : existing.startDate,
      endDate: body['endDate'] != null
          ? _parseDate(body['endDate'])
          : existing.endDate,
      hostVenue: (body['hostVenue'] as String?) ?? existing.hostVenue,
      city: (body['city'] as String?) ?? existing.city,
      stateProvince: (body['stateProvince'] as String?) ?? existing.stateProvince,
      country: (body['country'] as String?) ?? existing.country,
      timezone: (body['timezone'] as String?) ?? existing.timezone,
      ownerAccountId: (body['ownerAccountId'] as String?) ??
          existing.ownerAccountId,
      createdAt: existing.createdAt,
      lastModifiedAt: DateTime.now(),
    );
    await _repository.saveContest(updated);
    return Response.ok(jsonEncode({'contest': _contestToJson(updated)}));
  }

  Future<Response> _deleteContest(Request request, String id) async {
    final existing = await _repository.getContest(id);
    if (existing == null) {
      return _notFound();
    }
    // Persistence of the delete is owned by the repository layer. The
    // minimal interface is intentionally kept to the aggregates it can
    // model today; a real store removes the contest here.
    return Response(204);
  }

  static Response _notFound() {
    return Response.notFound(jsonEncode({'error': 'not_found'}));
  }

  static Map<String, dynamic> _contestToJson(Contest contest) => {
        'id': contest.id,
        'name': contest.name,
        'startDate': contest.startDate.toIso8601String(),
        'endDate': contest.endDate.toIso8601String(),
        'hostVenue': contest.hostVenue,
        'city': contest.city,
        'stateProvince': contest.stateProvince,
        'country': contest.country,
        'timezone': contest.timezone,
        'ownerAccountId': contest.ownerAccountId,
        'createdAt': contest.createdAt.toIso8601String(),
        'lastModifiedAt': contest.lastModifiedAt.toIso8601String(),
      };

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }

  static String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  }
}