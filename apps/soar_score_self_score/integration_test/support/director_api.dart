import 'dart:convert';

import 'package:http/http.dart' as http;

const String _apiBase = String.fromEnvironment('SOAR_SCORE_API_BASE_URL');

/// The F5J discipline profile and the pilot role: system data ids, the same
/// ones the server's own slice tests use.
const _f5jProfileId = '019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b01';
const _pilotRoleId = '019c0000-0000-7000-8000-000000000030';

/// The director's side, called straight on the API of the E2E server (which
/// acts as the Local account for every request), so the journey sets a
/// contest up without driving the contest app.
class DirectorApi {
  DirectorApi([String? base]) : _base = Uri.parse(base ?? _apiBase);

  final Uri _base;
  final http.Client _http = http.Client();

  Uri _uri(String path) => _base.replace(path: '/api/v1$path');

  Future<Map<String, Object?>> call(
    String method,
    String path, {
    Object? body,
    int status = 200,
  }) async {
    final request = http.Request(method, _uri(path))
      ..headers['content-type'] = 'application/json';
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(await _http.send(request));
    if (response.statusCode != status) {
      throw StateError(
        '$method $path answered ${response.statusCode}, expected $status: '
        '${response.body}',
      );
    }
    return response.body.isEmpty
        ? <String, Object?>{}
        : jsonDecode(response.body) as Map<String, Object?>;
  }
}

/// The contest the journey scores.
class SeededContest {
  SeededContest({
    required this.id,
    required this.links,
    required this.api,
    required this.pilotNames,
  });

  final String id;

  /// Invitation link per pilot name.
  final Map<String, String> links;
  final DirectorApi api;
  final List<String> pilotNames;

  /// The credential in [name]'s link (the last path segment).
  String credentialOf(String name) => Uri.parse(links[name]!).pathSegments.last;

  /// Moves the E2E server's invitation clock forward.
  Future<void> advanceClock(int hours) async {
    final response = await http.post(
      Uri.parse(
        '${const String.fromEnvironment('SOAR_SCORE_API_BASE_URL')}'
        '/__e2e/advance-clock?hours=$hours',
      ),
    );
    if (response.statusCode != 200) {
      throw StateError('advance-clock answered ${response.statusCode}');
    }
  }
}

String _uuid(int n) =>
    '019c0000-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}';

/// Creates an F5J contest with [pilots] pilots, a draw, scoring open, and one
/// invitation per pilot.
Future<SeededContest> seedContest({
  String name = 'E2E Self-Scoring Open',
  List<String> pilots = const [
    'Zoe Whitfield',
    'Milo Okafor',
    'Nadia Petrov',
    'Owen Quinn',
  ],
  int rounds = 2,
  int groups = 2,
}) async {
  final api = DirectorApi();
  // A contest under way now: a link expires with the contest's end.
  final start = DateTime.now().toUtc().subtract(const Duration(hours: 2));
  final end = start.add(const Duration(days: 1));
  final contestId = _uuid(0x7000);
  await api.call(
    'POST',
    '/contests',
    status: 201,
    body: {
      'id': contestId,
      'name': name,
      'start_date_time': start.toIso8601String(),
      'end_date_time': end.toIso8601String(),
      'timezone': 'America/Denver',
    },
  );
  await api.call(
    'POST',
    '/contests/$contestId/configuration',
    status: 201,
    body: {
      'base_revision_number': 0,
      'discipline_profile_id': _f5jProfileId,
      'config': {
        'core': <String, Object?>{},
        'discipline': {'working_time': 600},
      },
    },
  );
  final participations = <String, String>{};
  for (var i = 0; i < pilots.length; i++) {
    final parts = pilots[i].split(' ');
    final profileId = _uuid(0x7100 + i);
    final participationId = _uuid(0x7200 + i);
    await api.call(
      'POST',
      '/participants',
      status: 201,
      body: {
        'id': profileId,
        'first_name': parts.first,
        'last_name': parts.skip(1).join(' '),
      },
    );
    await api.call(
      'POST',
      '/contests/$contestId/participations',
      status: 201,
      body: {
        'id': participationId,
        'participant_profile_id': profileId,
        'role_id': _pilotRoleId,
      },
    );
    participations[pilots[i]] = participationId;
  }
  await api.call(
    'POST',
    '/contests/$contestId/matrix/draws',
    status: 201,
    body: {
      'id': _uuid(0x7300),
      'rounds': rounds,
      'groups_per_round': groups,
      'random_seed': 7,
    },
  );
  final contest = await api.call('GET', '/contests/$contestId');
  await api.call(
    'POST',
    '/contests/$contestId/actions',
    body: {'action': 'openScoring', 'base_revision': contest['revision']},
  );
  final issued = await api.call(
    'POST',
    '/contests/$contestId/invitations',
    body: {
      'request_id': 'e2e-invitations-1',
      'participation_ids': participations.values.toList(),
    },
  );
  final byParticipation = {
    for (final i in issued['invitations']! as List)
      (i as Map)['participation_id'] as String: i['link'] as String,
  };
  return SeededContest(
    id: contestId,
    api: api,
    pilotNames: pilots,
    links: {
      for (final e in participations.entries) e.key: byParticipation[e.value]!,
    },
  );
}
