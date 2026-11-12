import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/example_entities.dart';
import '../support/example_rows.dart';
import '../support/fixtures.dart';

/// Slot pointers for scores written before `current_attempt_id` existed.
void main() => forEachBackend(_tests);

const _placeholderId = '019c0000-0000-7000-8000-000000000301';
const _attemptId = '019c0000-0000-7000-8000-000000000401';
const _unscoredId = '019c0000-0000-7000-8000-000000000312';

void _tests(Backend backend) {
  late Installation inst;
  late int sequence;

  setUp(() async {
    inst = await Installation.open(backend);
    sequence = 0;
    final parents = <String>{};
    for (final (entity, _) in exampleEntities) {
      if (entity == 'ScorePlaceholder') break;
      parents.add(entity);
    }
    await loadExamples(inst, only: parents);
  });
  tearDown(() => inst.close());

  Map<String, Object?> example(String file, String id) =>
      exampleRows(file).firstWhere((row) => row['id'] == id);

  /// A change as a pre-upgrade service stored it: no slot pointer.
  Future<void> replay(
    String entityType,
    Map<String, Object?> payload, {
    int revision = 1,
  }) async {
    await inst.applier.apply(
      core.ReplicatedChange(
        scope: core.ContestScopeKey(
          core.Id.parse(payload['contest_id']! as String),
        ),
        sequence: ++sequence,
        entityType: entityType,
        entityId: core.Id.parse(payload['id']! as String),
        revision: revision,
        payload: payload,
        isDelete: false,
      ),
    );
  }

  Map<String, Object?> legacyPlaceholder(String id, {String? state}) =>
      {...example('score_placeholder', id), if (state != null) 'state': state}
        ..remove('current_attempt_id');

  Future<String?> pointerOf(String id) async {
    final row = await inst.stores
        .of('ScorePlaceholder')
        .findJson(core.Id.parse(id));
    return row!['current_attempt_id'] as String?;
  }

  test(
    'a scored slot gets its attempt when the rows arrive together',
    () async {
      await replay(
        'ScorePlaceholder',
        legacyPlaceholder(_placeholderId),
        revision: 3,
      );
      await replay('ScoreAttempt', example('score_attempt', _attemptId));
      await replay(
        'OfficialScore',
        example('official_score', '019c0000-0000-7000-8000-000000000501'),
      );

      expect(await pointerOf(_placeholderId), _attemptId);
    },
  );

  test('the pointer follows rows that arrive in later batches', () async {
    await replay(
      'ScorePlaceholder',
      legacyPlaceholder(_placeholderId),
      revision: 3,
    );
    expect(await pointerOf(_placeholderId), isNull);

    await replay('ScoreAttempt', example('score_attempt', _attemptId));
    expect(await pointerOf(_placeholderId), _attemptId);

    await replay(
      'OfficialScore',
      example('official_score', '019c0000-0000-7000-8000-000000000501'),
    );
    expect(await pointerOf(_placeholderId), _attemptId);
  });

  test('a submitted slot falls back to its latest attempt', () async {
    await replay(
      'ScorePlaceholder',
      legacyPlaceholder(_placeholderId, state: 'Submitted'),
      revision: 3,
    );
    await replay('ScoreAttempt', example('score_attempt', _attemptId));

    expect(await pointerOf(_placeholderId), _attemptId);
  });

  test('an unscored slot stays null', () async {
    await replay('ScorePlaceholder', legacyPlaceholder(_unscoredId));
    await replay(
      'ScorePlaceholder',
      legacyPlaceholder(_placeholderId),
      revision: 3,
    );
    await replay('ScoreAttempt', example('score_attempt', _attemptId));

    expect(await pointerOf(_unscoredId), isNull);
  });

  test('replaying again, or a newer snapshot, keeps the pointer', () async {
    await replay(
      'ScorePlaceholder',
      legacyPlaceholder(_placeholderId),
      revision: 3,
    );
    await replay('ScoreAttempt', example('score_attempt', _attemptId));
    await replay(
      'ScorePlaceholder',
      legacyPlaceholder(_placeholderId),
      revision: 3,
    );
    expect(await pointerOf(_placeholderId), _attemptId);

    final newer = {
      ...example('score_placeholder', _placeholderId),
      'current_attempt_id': _attemptId,
    };
    await replay('ScorePlaceholder', newer, revision: 4);
    expect(await pointerOf(_placeholderId), _attemptId);
  });

  test('a pointer a snapshot carries is not replaced', () async {
    final explicit = {
      ...example('score_placeholder', _placeholderId),
      'current_attempt_id': _attemptId,
    };
    await replay('ScorePlaceholder', explicit, revision: 3);
    await replay('ScoreAttempt', example('score_attempt', _attemptId));
    // A later attempt arriving does not move a pointer written by newer code.
    final later = {
      ...example('score_attempt', _attemptId),
      'id': core.Id.create().value,
      'accepted_at': '2030-01-01T00:00:00.000Z',
      'client_mutation_id': 'later-attempt',
    };
    await replay('ScoreAttempt', later);
    expect(await pointerOf(_placeholderId), _attemptId);
  });
}
