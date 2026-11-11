import 'dart:convert';

import 'package:http/http.dart' as http;

const String _apiBase = String.fromEnvironment('SOAR_SCORE_API_BASE_URL');

Uri _uri(String path) {
  final base = Uri.parse(_apiBase);
  return base.replace(path: '/api/v1$path');
}

Future<Map<String, Object?>> _json(
  http.Response response, {
  required int status,
  required String what,
}) async {
  if (response.statusCode != status) {
    throw StateError(
      '$what answered ${response.statusCode}, expected $status: '
      '${response.body}',
    );
  }
  return jsonDecode(response.body) as Map<String, Object?>;
}

/// Stores the own score of the first of [candidates] who has no score yet for [round] of the contest called
/// [contestName] as a pilot submission (a preliminary score the director has
/// not saved), through `POST /__e2e/pilot-submission` of the E2E server.
///
/// The contest app's journey runs on the installation profile, which has no
/// invitations, and the Windows build's embedded server has no such hook (a
/// real submission reaches it by sync from the hosted server), so this works
/// on the web run only. [timeFlown] is in seconds. Returns who submitted.
Future<String> submitAsPilot({
  required String contestName,
  required List<String> candidates,
  required int round,
  required int timeFlown,
  int launchHeight = 45,
}) async {
  final client = http.Client();
  try {
    final contests = await _json(
      await client.get(_uri('/contests')),
      status: 200,
      what: 'GET /contests',
    );
    final contest = (contests['contests']! as List).cast<Map>().singleWhere(
      (c) => c['name'] == contestName,
    );
    final contestId = contest['id']! as String;
    final participations = await _json(
      await client.get(_uri('/contests/$contestId/participations')),
      status: 200,
      what: 'GET participations',
    );
    final profiles = await _json(
      await client.get(_uri('/contests/$contestId/participants')),
      status: 200,
      what: 'GET participants',
    );
    final refusals = <String>[];
    for (final name in candidates) {
      final profileId = (profiles['participants']! as List)
          .cast<Map>()
          .singleWhere(
            (p) => '${p['first_name']} ${p['last_name']}' == name,
          )['id'];
      final participationId = (participations['participations']! as List)
          .cast<Map>()
          .singleWhere((p) => p['participant_profile_id'] == profileId)['id'];
      final response = await client.post(
        Uri.parse(_apiBase).replace(path: '/__e2e/pilot-submission'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'contest_id': contestId,
          'participation_id': participationId,
          'round': round,
          'components': {
            'time_flown': timeFlown,
            'launch_height': launchHeight,
            'landing': 'points_50',
          },
        }),
      );
      if (response.statusCode == 201) return name;
      if (response.statusCode != 409) {
        throw StateError(
          'pilot-submission answered ${response.statusCode}: ${response.body}',
        );
      }
      refusals.add('$name: ${response.body}');
    }
    throw StateError('No pilot could submit round $round: $refusals');
  } finally {
    client.close();
  }
}
