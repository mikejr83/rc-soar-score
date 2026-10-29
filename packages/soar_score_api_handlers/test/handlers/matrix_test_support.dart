import 'dart:async';

import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'handler_test_support.dart';

/// A [DrawRunner] that reports 40% and then waits for a cancel or [release],
/// so a test can cancel a running draw.
class HeldDrawRunner implements DrawRunner {
  final release = Completer<void>();

  /// Whether a draw waits for [release] or a cancel; otherwise it just runs.
  bool hold = true;
  final reported = Completer<void>();

  @override
  Future<DrawResult> run(
    DrawSpec spec, {
    void Function(DrawProgress progress)? onProgress,
    DrawCancellation? cancellation,
  }) async {
    if (!hold) return spec.generate();
    onProgress?.call(const DrawProgress(percent: 40, seed: 2, seedCount: 3));
    if (!reported.isCompleted) reported.complete();
    final cancelled = Completer<void>();
    cancellation?.onCancel(cancelled.complete);
    await Future.any([release.future, cancelled.future]);
    if (cancellation?.isCancelled ?? false) throw DrawCancelledError();
    return spec.generate();
  }
}

/// The contest every matrix edit test works on.
const matrixTestContestId = '019c0000-0000-7000-8000-000000000020';
const _contestId = matrixTestContestId;

String matrixTestProfileId(int n) =>
    '019c0000-0000-7000-8000-0000000001${_pad(n)}';
String matrixTestParticipationId(int n) =>
    '019c0000-0000-7000-8000-0000000002${_pad(n)}';
String _pad(int n) => n.toString().padLeft(2, '0');
String _profileId(int n) => matrixTestProfileId(n);
String _participationId(int n) => matrixTestParticipationId(n);

/// Creates, configures and draws a contest of [pilots] pilots in 3 rounds
/// of [groups] groups.
Future<void> drawnContest(
  HandlerHarness api, {
  int pilots = 6,
  int groups = 2,
  Map<String, Object?> core = const {},
  Future<void> Function()? beforeDraw,
  bool skipDraw = false,
}) async {
  await api.send(
    'POST',
    '/contests',
    body: {
      'id': _contestId,
      'name': 'Spring Open',
      'start_date_time': '2026-10-17T14:00:00.000Z',
      'end_date_time': '2026-10-18T22:00:00.000Z',
      'timezone': 'America/Denver',
    },
  );
  final configured = await api.send(
    'POST',
    '/contests/$_contestId/configuration',
    body: {
      'base_revision_number': 0,
      'discipline_profile_id': SystemDisciplineProfiles.f5jId.value,
      'config': {
        'core': core,
        'discipline': {'working_time': 600},
      },
    },
  );
  expect(configured.statusCode, 201, reason: '${await api.json(configured)}');
  for (var n = 1; n <= pilots; n++) {
    await api.send(
      'POST',
      '/participants',
      body: {'id': _profileId(n), 'first_name': 'P$n', 'last_name': 'X'},
    );
    await api.send(
      'POST',
      '/contests/$_contestId/participations',
      body: {
        'id': _participationId(n),
        'participant_profile_id': _profileId(n),
        'role_id': SystemRoles.pilotId.value,
      },
    );
  }
  await beforeDraw?.call();
  if (skipDraw) return;
  final response = await api.send(
    'POST',
    '/contests/$_contestId/matrix/draws',
    body: {
      'id': '019c0000-0000-7000-8000-000000000501',
      'rounds': 3,
      'groups_per_round': groups,
      'random_seed': 7,
    },
  );
  expect(response.statusCode, 201, reason: '${await api.json(response)}');
}

Future<List<Map<String, Object?>>> currentAssignments(
  HandlerHarness api,
) async {
  final matrix = await api.json(
    await api.send('GET', '/contests/$_contestId/matrix'),
  );
  return (matrix['assignments'] as List).cast<Map<String, Object?>>();
}

/// The current assignment of pilot [n] in the round with [ordinal].
Future<Map<String, Object?>> assignmentOfPilot(
  HandlerHarness api,
  int n, {
  int ordinal = 1,
}) async {
  final matrix = await api.json(
    await api.send('GET', '/contests/$_contestId/matrix'),
  );
  final round = (matrix['rounds'] as List).cast<Map>().firstWhere(
    (r) => r['ordinal'] == ordinal,
  );
  return (matrix['assignments'] as List)
      .cast<Map<String, Object?>>()
      .firstWhere(
        (a) =>
            a['contest_participation_id'] == _participationId(n) &&
            a['scheduled_round_id'] == round['id'],
      );
}
