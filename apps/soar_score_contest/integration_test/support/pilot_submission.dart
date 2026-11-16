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

/// Where a pilot is in a contest: the ids the E2E server's hooks take.
class _Pilot {
  _Pilot(this.contestId, this.participationId);

  final String contestId;
  final String participationId;
}

Future<Map<String, _Pilot>> _pilots(
  http.Client client,
  String contestName,
  Iterable<String> names,
) async {
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
  return {
    for (final name in names)
      name: _Pilot(
        contestId,
        (participations['participations']! as List).cast<Map>().singleWhere(
              (p) =>
                  p['participant_profile_id'] ==
                  (profiles['participants']! as List).cast<Map>().singleWhere(
                    (p) => '${p['first_name']} ${p['last_name']}' == name,
                  )['id'],
            )['id']!
            as String,
      ),
  };
}

Future<http.Response> _post(
  http.Client client,
  String hook,
  _Pilot pilot,
  int round,
  Map<String, Object?> components, {
  String? message,
}) => client.post(
  Uri.parse(_apiBase).replace(path: '/__e2e/$hook'),
  headers: {'content-type': 'application/json'},
  body: jsonEncode({
    'contest_id': pilot.contestId,
    'participation_id': pilot.participationId,
    'round': round,
    'components': components,
    'message': ?message,
  }),
);

Map<String, Object?> _flight(int timeFlown, int launchHeight) => {
  'time_flown': timeFlown,
  'launch_height': launchHeight,
  'landing': 'points_50',
};

/// Stores the own score of the first of [candidates] who has no score yet for
/// [round] of the contest called [contestName] as a pilot submission (a
/// preliminary score the director has not saved), through
/// `POST /__e2e/pilot-submission` of the E2E server.
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
}) async => (await submitAsPilots(
  contestName: contestName,
  candidates: candidates,
  round: round,
  count: 1,
  timeFlown: timeFlown,
  launchHeight: launchHeight,
)).single;

/// Like [submitAsPilot] for [count] pilots: the first [count] of [candidates]
/// who have no score yet for [round] each submit one, so a step can have
/// several pending rows (in one group or across groups). Returns who
/// submitted, in the order of [candidates]. The first pilot gets
/// [timeFlown], the next one second more, and so on, so the rows differ.
Future<List<String>> submitAsPilots({
  required String contestName,
  required List<String> candidates,
  required int round,
  required int count,
  required int timeFlown,
  int launchHeight = 45,
}) async {
  final client = http.Client();
  try {
    final pilots = await _pilots(client, contestName, candidates);
    final submitted = <String>[];
    final refusals = <String>[];
    for (final name in candidates) {
      if (submitted.length == count) break;
      final response = await _post(
        client,
        'pilot-submission',
        pilots[name]!,
        round,
        _flight(timeFlown + submitted.length, launchHeight),
      );
      if (response.statusCode == 201) {
        submitted.add(name);
      } else if (response.statusCode == 409) {
        refusals.add('$name: ${response.body}');
      } else {
        throw StateError(
          'pilot-submission answered ${response.statusCode}: ${response.body}',
        );
      }
    }
    if (submitted.length < count) {
      throw StateError(
        'Only ${submitted.length} of $count pilots could submit round $round: '
        '$refusals',
      );
    }
    return submitted;
  } finally {
    client.close();
  }
}

/// Opens a review request on [pilot]'s pending submission for [round], asking
/// for [timeFlown] seconds, through `POST /__e2e/pilot-review`: the slot
/// becomes `InReview`. Web run only, like [submitAsPilot].
Future<void> requestReviewAsPilot({
  required String contestName,
  required String pilot,
  required int round,
  required int timeFlown,
  int launchHeight = 45,
  String message = 'My timer read longer.',
}) async {
  final client = http.Client();
  try {
    final pilots = await _pilots(client, contestName, [pilot]);
    final response = await _post(
      client,
      'pilot-review',
      pilots[pilot]!,
      round,
      _flight(timeFlown, launchHeight),
      message: message,
    );
    if (response.statusCode != 201) {
      throw StateError(
        'pilot-review answered ${response.statusCode}: ${response.body}',
      );
    }
  } finally {
    client.close();
  }
}
