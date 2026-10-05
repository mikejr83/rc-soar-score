import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import 'package:soar_score_data/soar_score_data.dart';

import '../support/backends.dart';
import '../support/example_entities.dart';
import '../support/example_rows.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    await loadExamples(inst);
  });
  tearDown(() => inst.close());

  Future<void> put(String entity, Map<String, Object?> row) =>
      inst.stores.of(entity).upsertJson(row);

  /// A copy of the first example row of [file] with [changes] and a new id.
  Map<String, Object?> variant(
    String file, [
    Map<String, Object?> changes = const {},
  ]) => {...exampleRows(file).first, 'id': core.Id.create().value, ...changes};

  Future<void> rejects(String entity, Map<String, Object?> row) =>
      expectLater(put(entity, row), throwsA(anything));

  String id(String file, [int index = 0]) =>
      exampleRows(file)[index]['id']! as String;

  group('foreign keys', () {
    test('refuse a round of an unknown matrix revision', () async {
      await rejects(
        'Round',
        variant('round', {'matrix_revision_id': core.Id.create().value}),
      );
    });

    test('refuse a score attempt of an unknown placeholder', () async {
      await rejects(
        'ScoreAttempt',
        variant('score_attempt', {
          'score_placeholder_id': core.Id.create().value,
          'client_mutation_id': 'fk-1',
        }),
      );
    });

    test('refuse deleting a round that still has groups', () async {
      await expectLater(
        inst.stores.of('Round').remove(core.Id.parse(id('round'))),
        throwsA(anything),
      );
    });

    test('deleting a contest removes the matrix, scores and results', () async {
      await inst.stores.of('Contest').remove(core.Id.parse(id('contest')));

      for (final table in [
        'matrix_revisions',
        'rounds',
        'round_groups',
        'matrix_assignments',
        're_flights',
        're_flight_participants',
        'score_placeholders',
        'score_attempts',
        'official_scores',
        'review_requests',
        'flight_results',
        'participation_standings',
        'team_standings',
      ]) {
        expect(await inst.count(table), 0, reason: table);
      }
    });
  });

  group('unique keys', () {
    test('a revision number is taken once per contest', () async {
      await rejects('MatrixRevision', variant('matrix_revision'));
    });

    test('a round ordinal is taken once per matrix revision', () async {
      await rejects('Round', variant('round'));
    });

    test('a group number is taken once per round', () async {
      await rejects('RoundGroup', variant('round_group'));
    });

    test('a placeholder belongs to one assignment', () async {
      await rejects('ScorePlaceholder', variant('score_placeholder'));
    });

    test('a score revision is official once per placeholder', () async {
      await rejects('OfficialScore', variant('official_score'));
    });

    test('a client mutation id is used once per contest', () async {
      await rejects('ScoreAttempt', variant('score_attempt'));
    });

    test('a placeholder has one current flight result', () async {
      await rejects('FlightResult', variant('flight_result'));
    });

    test('a standing is kept once per round', () async {
      await rejects('ParticipationStanding', variant('participation_standing'));
      await rejects('TeamStanding', variant('team_standing'));
    });

    test('a pilot is listed once in a re-flight', () async {
      await rejects('ReFlightParticipant', variant('re_flight_participant'));
    });
  });

  group('partial unique indexes', () {
    test('a live round ordinal is taken once per contest', () async {
      // A second matrix revision may not reuse an ordinal still in play.
      final revision = variant('matrix_revision', {
        'revision_number': 2,
        'previous_revision_id': id('matrix_revision'),
      });
      await put('MatrixRevision', revision);
      await rejects(
        'Round',
        variant('round', {'matrix_revision_id': revision['id']}),
      );
    });

    test('a cancelled round frees its ordinal', () async {
      final revision = variant('matrix_revision', {
        'revision_number': 2,
        'previous_revision_id': id('matrix_revision'),
        'finalized_by': null,
        'finalized_at': null,
      });
      await put('MatrixRevision', revision);
      await put(
        'Round',
        variant('round', {
          'matrix_revision_id': revision['id'],
          'status': 'Cancelled',
        }),
      );
    });

    test('two finalized revisions cannot extend the same one', () async {
      await put(
        'MatrixRevision',
        variant('matrix_revision', {
          'revision_number': 2,
          'previous_revision_id': id('matrix_revision'),
        }),
      );
      await rejects(
        'MatrixRevision',
        variant('matrix_revision', {
          'revision_number': 3,
          'previous_revision_id': id('matrix_revision'),
        }),
      );
    });

    test('a pilot flies a credited round once', () async {
      final source = exampleRows('matrix_assignment').first;
      await rejects(
        'MatrixAssignment',
        variant('matrix_assignment', {
          'group': 2,
          'contest_participation_id': source['contest_participation_id'],
        }),
      );
    });

    test('a lane holds one pilot per group', () async {
      final taken = variant('matrix_assignment', {'lane': 1});
      await put('MatrixAssignment', {...taken, 'id': id('matrix_assignment')});
      await rejects(
        'MatrixAssignment',
        variant('matrix_assignment', {
          'lane': 1,
          'contest_participation_id': exampleRows(
            'matrix_assignment',
          )[1]['contest_participation_id'],
        }),
      );
    });

    test('a score has one open review request', () async {
      final open = variant('review_request', {
        'state': 'Submitted',
        'decision_actor_id': null,
        'decision_time': null,
        'decision_message': null,
        'resulting_attempt_id': null,
      });
      await put('ReviewRequest', open);
      await rejects('ReviewRequest', {...open, 'id': core.Id.create().value});
    });
  });

  group('checks', () {
    test('enumerated columns accept only their values', () async {
      await rejects('Round', variant('round', {'status': 'Paused'}));
      await rejects(
        'MatrixAssignment',
        variant('matrix_assignment', {'assignment_type': 'Teleport'}),
      );
    });

    test('a locked group has a lock time', () async {
      await rejects(
        'RoundGroup',
        variant('round_group', {
          'group_number': 9,
          'status': 'Locked',
          'locked_at': null,
        }),
      );
    });

    test('a moved assignment names its source', () async {
      await rejects(
        'MatrixAssignment',
        variant('matrix_assignment', {
          'group': 2,
          'assignment_type': 'Moved',
          'reason': 'x',
          'source_assignment_id': null,
        }),
      );
    });

    test('a score reset needs the Moved or Reflight type', () async {
      await rejects(
        'MatrixAssignment',
        variant('matrix_assignment', {'group': 2, 'reset_score_revision': 1}),
      );
    });

    test('an excluded re-flight pilot has a reason', () async {
      await rejects(
        'ReFlightParticipant',
        variant('re_flight_participant', {
          'contest_participation_id': id('contest_participation', 1),
          'role': 'Excluded',
          'excluded_reason': null,
        }),
      );
    });

    test('a flight result has no negative points', () async {
      await rejects(
        'FlightResult',
        variant('flight_result', {
          'score_placeholder_id': id('score_placeholder', 1),
          'raw_points': -1,
        }),
      );
    });

    test('a decided review request has its decision', () async {
      await rejects(
        'ReviewRequest',
        variant('review_request', {
          'state': 'Submitted',
          'decision_actor_id': id('contest_participation'),
        }),
      );
    });
  });
}
