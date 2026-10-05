import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import 'package:soar_score_data/soar_score_data.dart';

import '../support/backends.dart';
import '../support/example_entities.dart';
import '../support/example_rows.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

const _round81 = '019c0000-0000-7000-8000-000000000081';
const _round82 = '019c0000-0000-7000-8000-000000000082';

void _tests(Backend backend) {
  late Installation inst;
  late core.MatrixAssignment source;
  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    await loadExamples(inst);
    source = core.MatrixAssignment.fromJson(
      exampleRows('matrix_assignment').first,
    );
  });
  tearDown(() => inst.close());

  /// Moves the pilot of [from] to group 2 of the second round, credited to
  /// the round they were drawn into.
  core.MatrixAssignment moveOf(core.MatrixAssignment from) =>
      core.MatrixAssignment.fromJson({
        ...from.toJson(),
        'id': core.Id.create().value,
        'scheduled_round_id': _round82,
        'group': 2,
        'assignment_type': 'Moved',
        'source_assignment_id': from.id.value,
        'reason': 'Moved to the later round',
        'created_at': '2026-10-17T16:00:00Z',
      });

  Future<core.MatrixAssignment> stored(core.Id id) async =>
      (await inst.stores.of('MatrixAssignment').find(id))!
          as core.MatrixAssignment;

  Future<void> move(core.MatrixAssignment moved) =>
      inst.unitOfWork.run((c) => c.moveAssignment(moved, metadata: metadata()));

  test('stores the new row and marks the old one', () async {
    final moved = moveOf(source);

    await move(moved);

    expect(await stored(moved.id), moved);
    expect((await stored(source.id)).supersededByAssignmentId, moved.id);
  });

  test('records one mutation naming the assignment it supersedes', () async {
    final before = await inst.count('mutation_records');
    final moved = moveOf(source);

    await move(moved);

    expect(await inst.count('mutation_records'), before + 1);
    final row = await inst.db
        .customSelect(
          "SELECT entity_type, payload FROM mutation_records "
          "WHERE entity_id = '${moved.id.value}'",
        )
        .getSingle();
    expect(row.read<String>('entity_type'), 'MatrixAssignment');
    expect(row.read<String>('payload'), contains(source.id.value));
    expect(row.read<String>('payload'), contains('"supersedes"'));
  });

  test('a second move from the same source keeps nothing', () async {
    final first = moveOf(source);
    await move(first);
    final assignments = await inst.count('matrix_assignments');
    final mutations = await inst.count('mutation_records');

    await expectLater(
      move(moveOf(source)),
      throwsA(isA<core.AlreadySupersededError>()),
    );

    expect(await inst.count('matrix_assignments'), assignments);
    expect(await inst.count('mutation_records'), mutations);
    expect((await stored(source.id)).supersededByAssignmentId, first.id);
  });

  test('a move can start from the row that superseded another', () async {
    final first = moveOf(source);
    await move(first);

    final second = core.MatrixAssignment.fromJson({
      ...moveOf(first).toJson(),
      'scheduled_round_id': _round81,
      'group': 1,
      'lane': 3,
    });
    await move(second);

    expect((await stored(first.id)).supersededByAssignmentId, second.id);
  });

  test('refuses an assignment that is not a Moved one', () async {
    final original = core.MatrixAssignment.fromJson({
      ...source.toJson(),
      'id': core.Id.create().value,
    });

    await expectLater(move(original), throwsA(isA<ArgumentError>()));
  });

  test('refuses a move from a source that is not stored', () async {
    final orphan = core.MatrixAssignment.fromJson({
      ...moveOf(source).toJson(),
      'source_assignment_id': core.Id.create().value,
    });

    await expectLater(move(orphan), throwsA(isA<ArgumentError>()));
  });

  test('a row that clashes with a live assignment is refused whole', () async {
    // The pilot already flies a live row credited to round 82.
    final clash = core.MatrixAssignment.fromJson({
      ...moveOf(source).toJson(),
      'credited_round_id': _round82,
    });

    await expectLater(move(clash), throwsA(anything));

    expect((await stored(source.id)).supersededByAssignmentId, isNull);
  });
}
