import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/drawn_contest.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

/// A pilot with matrix rows but no scores leaves them behind when they are
/// removed or stop flying; one with a score does not, against the real
/// repositories.
void _tests(Backend backend) {
  group('ParticipationsService and a drawn matrix', () {
    late Installation inst;
    late Repository repository;
    late ParticipationsService service;
    late core.Id contestId;
    final actor = core.Id.create();

    setUp(() async {
      inst = await Installation.open(backend);
      await SystemDataSeeder(inst.db).seed();
      repository = Repository(inst.db);
      service = ParticipationsService(repository);
      contestId = await drawnContest(repository, actor);
    });

    tearDown(() => inst.close());

    var mutations = 0;
    core.MutationMetadata meta() => core.MutationMetadata(
      clientMutationId: 'request-${mutations++}',
      authority: core.Authority.director,
      clientTime: DateTime.utc(2026, 10, 8),
      actorId: actor,
    );

    Future<List<core.ContestParticipation>> pilots() =>
        repository.contestParticipationRepository.listForContest(contestId);

    Future<List<core.MatrixAssignment>> rowsOf(core.ContestParticipation p) =>
        repository.matrixAssignmentRepository.listForParticipation(p.id);

    Future<void> score(core.ContestParticipation pilot) async {
      final assignment = (await rowsOf(pilot)).first;
      await ScoresService(repository).enterOfficialScore(
        contestId,
        assignment.id,
        clientMutationId: 'score-${pilot.id.value}',
        baseScoreRevision: 0,
        components: const {
          'time_flown': 540,
          'launch_height': 200,
          'landing': 'points_50',
        },
        actorId: actor,
        metadata: meta(),
      );
    }

    test('removing a pilot with no scores removes their rows and slots, '
        'leaving a tombstone for each', () async {
      final all = await pilots();
      final leaving = all.first;
      final rows = await rowsOf(leaving);
      expect(rows, hasLength(2));
      final revisions = await inst.count('matrix_revisions');
      final assignments = await inst.count('matrix_assignments');
      final placeholders = await inst.count('score_placeholders');
      final tombstones = await inst.count('tombstones');

      final removed = await service.remove(
        contestId,
        leaving.id,
        metadata: meta(),
      );

      expect(removed, 2);
      expect(await pilots(), hasLength(all.length - 1));
      expect(await rowsOf(leaving), isEmpty);
      expect(await inst.count('matrix_assignments'), assignments - 2);
      expect(await inst.count('score_placeholders'), placeholders - 2);
      // Two assignments, two placeholders and the participation.
      expect(await inst.count('tombstones'), tombstones + 5);
      expect(await inst.count('matrix_revisions'), revisions);
      for (final other in all.skip(1)) {
        expect(await rowsOf(other), hasLength(2));
      }
    });

    test('removing a pilot, or making them a non-flier, removes their '
        'model links with a tombstone each', () async {
      final all = await pilots();
      final models = ModelsService(repository);
      Future<void> addLinks(core.ContestParticipation pilot) async {
        for (final name in ['Main', 'Spare']) {
          await models.addLink(
            contestId,
            actor,
            pilot.id,
            id: core.Id.create(),
            modelName: name,
            metadata: meta(),
          );
        }
      }

      await addLinks(all[0]);
      await addLinks(all[1]);
      final links = repository.contestModelLinkRepository;
      expect(await links.listForContest(contestId), hasLength(4));
      final tombstones = await inst.count('tombstones');

      await service.remove(contestId, all[0].id, metadata: meta());

      expect(await links.listForParticipation(all[0].id), isEmpty);
      expect(await links.listForParticipation(all[1].id), hasLength(2));
      // Two assignments, two placeholders, two links and the participation.
      expect(await inst.count('tombstones'), tombstones + 7);

      await service.update(
        contestId,
        actor,
        all[1].id,
        roleId: core.SystemRoles.helperId,
        baseRevision: all[1].revision,
        metadata: meta(),
      );

      expect(await links.listForContest(contestId), isEmpty);
    });

    test('a pilot with no matrix rows is removed as before', () async {
      final helper = await ParticipantsService(repository).create(
        actor,
        core.Id.create(),
        ParticipantDetails(firstName: 'Helper', lastName: 'Test'),
        metadata: meta(),
      );
      final participation = await service.add(
        contestId,
        actor,
        id: core.Id.create(),
        participantProfileId: helper.id,
        roleId: core.SystemRoles.helperId,
        metadata: meta(),
      );

      final removed = await service.remove(
        contestId,
        participation.id,
        metadata: meta(),
      );

      expect(removed, 0);
    });

    test('a pilot is refused when every group of a round is full', () async {
      final profile = await ParticipantsService(repository).create(
        actor,
        core.Id.create(),
        ParticipantDetails(firstName: 'Late', lastName: 'Test'),
        metadata: meta(),
      );
      final before = (await pilots()).length;

      await expectLater(
        service.add(
          contestId,
          actor,
          id: core.Id.create(),
          participantProfileId: profile.id,
          metadata: meta(),
        ),
        throwsA(
          isA<core.ContestStateError>().having(
            (e) => e.code,
            'code',
            'no_room_in_round',
          ),
        ),
      );

      expect(await pilots(), hasLength(before));
    });

    test('a pilot with a score is refused and keeps everything', () async {
      final scored = (await pilots()).first;
      await score(scored);
      final assignments = await inst.count('matrix_assignments');

      await expectLater(
        service.remove(contestId, scored.id, metadata: meta()),
        throwsA(
          isA<core.ContestStateError>().having(
            (e) => e.code,
            'code',
            'has_scores',
          ),
        ),
      );

      expect(await pilots(), contains(scored));
      expect(await inst.count('matrix_assignments'), assignments);
    });

    test('an unscored pilot leaves while results of others exist', () async {
      final all = await pilots();
      await score(all.first);
      await ResultsService(repository).recalculate(contestId);
      final leaving = all.last;
      final standings = await inst.count('participation_standings');
      expect(standings, greaterThan(0));

      await service.remove(contestId, leaving.id, metadata: meta());

      expect(await pilots(), isNot(contains(leaving)));
      expect(await inst.count('participation_standings'), lessThan(standings));
      final results = await ResultsService(repository).recalculate(contestId);
      expect(results.isStale, isFalse);
    });

    test(
      'becoming a non-flier removes the rows of an unscored pilot',
      () async {
        final pilot = (await pilots()).first;

        final change = await service.update(
          contestId,
          actor,
          pilot.id,
          roleId: core.SystemRoles.helperId,
          baseRevision: pilot.revision,
          metadata: meta(),
        );

        expect(change.matrixRowsRemoved, 2);
        expect(change.participation.roleType, core.RoleType.nonFlier);
        expect(await rowsOf(pilot), isEmpty);
      },
    );

    test('a pilot with a score cannot become a non-flier', () async {
      final pilot = (await pilots()).first;
      await score(pilot);
      final current = (await repository.contestParticipationRepository.findById(
        pilot.id,
      ))!;

      await expectLater(
        service.update(
          contestId,
          actor,
          pilot.id,
          roleId: core.SystemRoles.helperId,
          baseRevision: current.revision,
          metadata: meta(),
        ),
        throwsA(
          isA<core.ContestStateError>().having(
            (e) => e.code,
            'code',
            'has_scores',
          ),
        ),
      );

      expect(await rowsOf(pilot), hasLength(2));
    });

    test('a stale revision removes nothing', () async {
      final pilot = (await pilots()).first;

      await expectLater(
        service.update(
          contestId,
          actor,
          pilot.id,
          roleId: core.SystemRoles.helperId,
          baseRevision: pilot.revision + 1,
          metadata: meta(),
        ),
        throwsA(isA<core.StaleRevisionError>()),
      );

      expect(await rowsOf(pilot), hasLength(2));
    });

    test('the rows and the role change together: a save that lost to another '
        'edit removes nothing', () async {
      final pilot = (await pilots()).first;
      // Another edit lands between the service's check and its save.
      await repository.contestParticipationRepository.save(
        core.ContestParticipation.fromJson({
          ...pilot.toJson(),
          'classification': 'Open',
        }),
        metadata: meta(),
      );
      final helper = (await repository.roleRepository.listVisibleTo())
          .firstWhere((r) => r.id == core.SystemRoles.helperId);
      final demoted = core.ContestParticipation.fromJson({
        ...pilot.toJson(),
        'role_id': helper.id.value,
        'role_name': helper.displayName,
        'role_type': 'NonFlier',
      });

      await expectLater(
        repository.contestParticipationRepository.saveRemovingMatrixRows(
          demoted,
          metadata: meta(),
        ),
        throwsA(isA<core.StaleRevisionError>()),
      );

      expect(await rowsOf(pilot), hasLength(2));
      expect(await inst.count('score_placeholders'), 8);
    });

    test('a slot that gained a score before the save refuses the whole '
        'change', () async {
      final pilot = (await pilots()).first;
      await score(pilot);
      final current = (await repository.contestParticipationRepository.findById(
        pilot.id,
      ))!;

      await expectLater(
        repository.contestParticipationRepository.saveRemovingMatrixRows(
          current,
          metadata: meta(),
        ),
        throwsA(isA<core.ContestStateError>()),
      );

      expect(await rowsOf(pilot), hasLength(2));
    });

    /// Gives [pilot] a third row, as another device's move would.
    Future<void> addMovedRow(core.ContestParticipation pilot) async {
      final source = (await rowsOf(pilot)).first;
      final moved = core.MatrixAssignment.fromJson({
        ...source.toJson(),
        'id': core.Id.create().value,
        'group': 2,
        'assignment_type': 'Moved',
        'source_assignment_id': source.id.value,
        'reason': 'Moved to group 2',
        'created_at': '2026-10-17T16:00:00Z',
      });
      await inst.unitOfWork.run(
        (c) => c.moveAssignment(moved, metadata: meta()),
      );
      await inst.unitOfWork.run(
        (c) => c.save(
          core.ScorePlaceholder(
            id: core.Id.create(),
            contestId: contestId,
            contestParticipationId: pilot.id,
            assignmentId: moved.id,
          ),
          metadata: meta(),
        ),
      );
    }

    test('removing counts the rows the transaction removed, including one '
        'that appeared after the service looked', () async {
      final pilot = (await pilots()).first;
      final interleaved = _Interleaving(inst.db, () => addMovedRow(pilot));

      final removed = await ParticipationsService(interleaved)
          .remove(contestId, pilot.id, metadata: meta());

      expect(removed, 3);
      expect(await rowsOf(pilot), isEmpty);
    });

    test('demoting counts the rows the transaction removed, including one '
        'that appeared after the service looked', () async {
      final pilot = (await pilots()).first;
      final interleaved = _Interleaving(inst.db, () => addMovedRow(pilot));

      final result = await ParticipationsService(interleaved).update(
        contestId,
        actor,
        pilot.id,
        roleId: core.SystemRoles.helperId,
        baseRevision: pilot.revision,
        metadata: meta(),
      );

      expect(result.matrixRowsRemoved, 3);
      expect(await rowsOf(pilot), isEmpty);
    });

    test('both ends of a move go together', () async {
      final pilot = (await pilots()).first;
      await addMovedRow(pilot);

      final removed = await service.remove(
        contestId,
        pilot.id,
        metadata: meta(),
      );

      expect(removed, 3);
      expect(await rowsOf(pilot), isEmpty);
    });
  });
}

/// A repository whose participation changes first run [beforeChange], so a
/// test can change the matrix after the service has read it and before the
/// transaction that removes the rows.
class _Interleaving extends Repository {
  _Interleaving(super.database, Future<void> Function() beforeChange)
    : _participations = _Hooked(
        ContestParticipationRepository(
          database,
          stores: EntityStores.forDatabase(database),
        ),
        beforeChange,
      );

  final core.ContestParticipationRepository _participations;

  @override
  core.ContestParticipationRepository get contestParticipationRepository =>
      _participations;
}

class _Hooked implements core.ContestParticipationRepository {
  _Hooked(this._inner, this._beforeChange);

  final core.ContestParticipationRepository _inner;
  final Future<void> Function() _beforeChange;

  @override
  Future<core.ContestParticipation?> findById(core.Id id) =>
      _inner.findById(id);

  @override
  Future<List<core.ContestParticipation>> listForContest(core.Id contestId) =>
      _inner.listForContest(contestId);

  @override
  Future<List<core.ContestParticipation>> listForProfile(core.Id id) =>
      _inner.listForProfile(id);

  @override
  Future<List<core.ContestParticipation>> listForRole(core.Id roleId) =>
      _inner.listForRole(roleId);

  @override
  Future<core.ContestParticipation> save(
    core.ContestParticipation participation, {
    required core.MutationMetadata metadata,
    core.AuditEvent? audit,
  }) => _inner.save(participation, metadata: metadata, audit: audit);

  @override
  Future<({core.ContestParticipation participation, int matrixRowsRemoved})>
  saveRemovingMatrixRows(
    core.ContestParticipation participation, {
    required core.MutationMetadata metadata,
    core.AuditEvent? audit,
  }) async {
    await _beforeChange();
    return _inner.saveRemovingMatrixRows(
      participation,
      metadata: metadata,
      audit: audit,
    );
  }

  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      _inner.delete(id, metadata: metadata);

  @override
  Future<({bool deleted, int matrixRowsRemoved})> deleteRemovingMatrixRows(
    core.Id id, {
    required core.MutationMetadata metadata,
  }) async {
    await _beforeChange();
    return _inner.deleteRemovingMatrixRows(id, metadata: metadata);
  }
}
