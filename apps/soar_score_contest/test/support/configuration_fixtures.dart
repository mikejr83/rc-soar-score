import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:soar_score_core/soar_score_core.dart';

const configContestId = '019c0000-0000-7000-8000-000000000017';
final _created = DateTime.utc(2026, 9);

Contest configContest({
  LifecycleState state = LifecycleState.configuring,
  AdminLock lock = AdminLock.unlocked,
}) => Contest(
  id: Id.parse(configContestId),
  name: 'Front Range F5J Open',
  startDateTime: DateTime.utc(2026, 10, 17, 12),
  endDateTime: DateTime.utc(2026, 10, 18, 12),
  timezone: 'America/Denver',
  host: 'Front Range Soaring Club',
  lifecycleState: state,
  adminLock: lock,
  createdAt: _created,
  updatedAt: _created,
);

/// The F5J system profile's default landing table.
final f5jLandingTableId = Id.parse('019a3c4a-8f2a-7b1c-9d4e-6f5a3b2c2b02');
final clubLandingTableId = Id.parse('019c0000-0000-7000-8000-0000000000f2');

/// An F5J configuration revision with the official discipline options.
ContestConfigurationRevision configRevision(
  int number, {
  Map<String, Object?> core = const {},
  Map<String, Object?> discipline = const {},
}) => ContestConfigurationRevision(
  id: Id.parse('019c0000-0000-7000-8000-0000000000a$number'),
  contestId: Id.parse(configContestId),
  revisionNumber: number,
  disciplineProfileId: SystemDisciplineProfiles.f5jId,
  config: ContestConfig(core: core, discipline: discipline),
  landingTableId: f5jLandingTableId,
  createdBy: Id.parse('019c0000-0000-7000-8000-0000000000b1'),
  createdAt: _created,
);

ContestParticipation configParticipation(
  int n, {
  RoleType type = RoleType.pilot,
}) => ContestParticipation(
  id: Id.parse('019c0000-0000-7000-8000-00000000010$n'),
  contestId: Id.parse(configContestId),
  participantProfileId: Id.parse('019c0000-0000-7000-8000-00000000020$n'),
  roleId: Id.parse('019c0000-0000-7000-8000-0000000000c1'),
  roleName: 'Pilot',
  roleType: type,
  scoringUuid: ScoringUuid.parse('0000000$n-0000-4000-8000-000000000000'),
);

CurrentMatrix configDrawnMatrix() => CurrentMatrix(
  revision: MatrixRevision(
    id: Id.parse('019c0000-0000-7000-8000-0000000000e1'),
    contestId: Id.parse(configContestId),
    revisionNumber: 1,
    firstRound: 1,
    lastRound: 4,
    drawMode: DrawMode.standardManOnMan,
    randomSeed: 1,
    algorithmVersion: '1',
    drawConfig: const {
      'groups_per_round': 2,
      'team_protection': false,
      'lane_mode': 'None',
      'configured_draw_mode': 'StandardManOnMan',
    },
    seedingSnapshot: const {},
    createdBy: Id.parse('019c0000-0000-7000-8000-0000000000b1'),
    createdAt: _created,
  ),
);

LandingTableView _landing(Id id, String name, {Id? owner}) => LandingTableView(
  content: LandingTableWithResults(
    table: LandingTable(
      id: id,
      ownerAccountId: owner,
      name: name,
      inputUnit: LandingInputUnit.meters,
      createdAt: _created,
    ),
    results: [
      for (var i = 0; i < 3; i++)
        LandingResult(
          id: Id.parse('019c0000-0000-7000-8000-00000000030$i'),
          landingTableId: id,
          entryKey: '$i',
          displayValue: '$i m',
          pointValue: 50 - i * 5,
          ordinalPosition: i,
        ),
    ],
  ),
  inUse: true,
);

/// A fake server for the configuration page.
class ConfigServer {
  ConfigServer({
    Contest? contest,
    this.revision,
    this.participations = const [],
    CurrentMatrix? matrix,
    this.conflictOnSave = false,
  }) : contest = contest ?? configContest(),
       matrix = matrix ?? CurrentMatrix();

  Contest contest;
  final ContestConfigurationRevision? revision;
  final List<ContestParticipation> participations;
  final CurrentMatrix matrix;

  /// The first configuration save fails with 409, as if another device saved
  /// first.
  bool conflictOnSave;

  Map<String, dynamic>? saved;
  Map<String, dynamic>? updatedContest;

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    if (request.method == 'POST' && path.endsWith('/configuration')) {
      if (conflictOnSave) {
        conflictOnSave = false;
        return _json({
          'error': {'code': 'stale_revision', 'message': 'newer revision'},
        }, 409);
      }
      saved = jsonDecode(request.body) as Map<String, dynamic>;
      return _json(
        SavedConfiguration(
          revision: configRevision(
            2,
            core: {
              ...?revision?.config.core,
              ...(saved!['config'] as Map)['core'] as Map<String, Object?>,
            },
          ),
          contest: contest,
        ).toJson(),
      );
    }
    if (request.method == 'PUT' && path.contains('/contests/')) {
      updatedContest = jsonDecode(request.body) as Map<String, dynamic>;
      return _json(contest.toJson());
    }
    if (path.endsWith('/configuration')) {
      return revision == null
          ? _json({
              'error': {'code': 'not_found', 'message': 'none'},
            }, 404)
          : _json(revision!.toJson());
    }
    if (path.endsWith('/participations')) {
      return _json({
        'participations': [for (final p in participations) p.toJson()],
      });
    }
    if (path.endsWith('/teams')) {
      return _json({'teams': <Object>[]});
    }
    if (path.endsWith('/landing-tables')) {
      return _json({
        'landing_tables': [
          _landing(f5jLandingTableId, 'F5J standard').toJson(),
          _landing(
            clubLandingTableId,
            'Club tape',
            owner: Id.parse('019c0000-0000-7000-8000-0000000000b1'),
          ).toJson(),
        ],
      });
    }
    if (path.endsWith('/matrix')) {
      return _json(matrix.toJson());
    }
    return _json(contest.toJson());
  }
}
