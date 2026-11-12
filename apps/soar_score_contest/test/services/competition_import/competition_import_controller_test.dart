import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/competition_import/competition_import.dart';
import 'package:soar_score_contest/services/pilot_import/pilot_import.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/competition_import_fakes.dart';

void main() {
  late FakeCompetitionImportStore store;
  late String? chosenPath;
  late CompetitionImportController controller;

  CompetitionImportController build({
    Future<GliderScoreImportResult> Function(String path)? read,
    Future<MappedGliderScoreFile> Function(GliderScoreImportResult)? mapFile,
  }) => CompetitionImportController(
    store: store,
    readFile: read ?? (_) async => competitionsSnapshot(),
    files: GliderScoreFiles(choose: () async => chosenPath),
    // The tests map in place; the app maps on a background isolate.
    mapFile: mapFile ?? (result) async => mapGliderScoreFile(result),
  );

  setUp(() {
    store = FakeCompetitionImportStore([]);
    chosenPath = r'C:\Files\Contest.mdb';
    controller = build();
  });
  tearDown(() => controller.dispose());

  test('reads the file and lists competitions with none chosen', () async {
    expect(controller.step, CompetitionImportStep.idle);
    expect(await controller.chooseAndRead(), isTrue);

    expect(controller.step, CompetitionImportStep.competitions);
    expect(controller.fileName, 'Contest.mdb');
    final all = controller.listed;
    expect(all.map((p) => p.sourceCompNo), [2, 4, 3, 1]);
    expect(controller.importable.map((p) => p.sourceCompNo), [1, 2]);
    expect(controller.chosen, isEmpty);
    expect(controller.planOf(3)!.isImportable, isFalse);
    expect(
      controller.planOf(4)!.contest.reason,
      ContestImportReason.noParticipants,
    );
    // The scores come with the competition.
    expect(controller.planOf(1)!.flights, hasLength(4));
    expect(controller.planOf(1)!.completedByDefault, isTrue);
  });

  test(
    'maps the file through the injected mapper, off the UI thread',
    () async {
      final mapping = Completer<MappedGliderScoreFile>();
      var asked = 0;
      controller.dispose();
      controller = build(
        mapFile: (_) {
          asked++;
          return mapping.future;
        },
      );
      final reading = controller.chooseAndRead();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // While the mapper works the wizard shows the reading state.
      expect(asked, 1);
      expect(controller.step, CompetitionImportStep.reading);

      mapping.complete(mapGliderScoreFile(competitionsSnapshot()));
      await reading;
      expect(controller.step, CompetitionImportStep.competitions);
    },
  );

  test('lists competitions newest first, undated last, ties by name', () async {
    GliderScoreImportResult snapshot() {
      Map<String, Object?> comp(int no, String name, String? date) => {
        'CompNo': no,
        'CompName': name,
        'GSCompClass': 'F5J',
        'CompDate': ?date,
      };
      final rows = [
        comp(1, 'Spring', '03/14/26 00:00:00'),
        comp(2, 'Autumn', '10/10/26 00:00:00'),
        comp(3, 'No date', null),
        comp(4, 'Beta', '06/14/26 00:00:00'),
        comp(5, 'Alpha', '06/14/26 00:00:00'),
      ];
      return GliderScoreImportResult(
        id: Id.create(),
        sourceDbFile: 'Contest.mdb',
        tables: [
          GliderScoreTable(
            name: 'Comps',
            rows: rows,
            rowCount: rows.length,
            rowCapExceeded: false,
          ),
        ],
      );
    }

    final c = build(read: (_) async => snapshot());
    addTearDown(c.dispose);
    await c.chooseAndRead();
    expect(c.listed.map((p) => p.sourceCompNo), [2, 5, 4, 1, 3]);
  });

  test('cancelling the chooser leaves the wizard idle', () async {
    chosenPath = null;
    expect(await controller.chooseAndRead(), isFalse);
    expect(controller.step, CompetitionImportStep.idle);
  });

  test('only importable competitions can be chosen', () async {
    await controller.chooseAndRead();
    controller.toggle(3);
    controller.toggle(4);
    expect(controller.chosen, isEmpty);

    controller.toggle(1);
    expect(controller.chosen, {1});
    controller.toggle(1);
    expect(controller.chosen, isEmpty);

    controller.setAll(true);
    expect(controller.chosen, {1, 2});
    controller.setAll(false);
    expect(controller.chosen, isEmpty);
  });

  test('cannot continue with nothing chosen', () async {
    await controller.chooseAndRead();
    await controller.continueToPilots();
    expect(controller.step, CompetitionImportStep.competitions);
  });

  test('reviews only the pilots of the chosen competitions', () async {
    await controller.chooseAndRead();
    controller.toggle(2);
    await controller.continueToPilots();

    expect(controller.step, CompetitionImportStep.pilots);
    expect(
      [for (final m in controller.pilots.review!.matches) m.draft.lastName],
      ['Lovelace'],
    );

    controller.backToCompetitions();
    controller.toggle(1);
    await controller.continueToPilots();
    expect([
      for (final m in controller.pilots.review!.matches) m.draft.lastName,
    ], unorderedEquals(['Lovelace', 'Nilsson']));
  });

  test('a link from one competition is reused for another', () async {
    final ada = ParticipantProfile(
      id: Id.create(),
      ownerAccountId: Id.create(),
      firstName: 'Ada',
      lastName: 'Lovelace',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    const draft = PilotDraft(
      sourcePilotNo: 1,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );
    store.profiles.add(ada);
    store.links.add(
      PilotImportLink(
        id: Id.create(),
        ownerAccountId: ada.ownerAccountId,
        sourcePilotNo: 1,
        participantProfileId: ada.id,
        sourceValues: PilotImportMatcher.sourceValues(draft),
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
    await controller.chooseAndRead();
    controller.toggle(2);
    await controller.continueToPilots();
    final match = controller.pilots.review!.matches.single;
    expect(match.remembered, isTrue);
    expect(controller.pilots.selections.single.targetProfileId, ada.id);
    expect(
      controller.pilots.selections.single.choice,
      PilotImportChoice.update,
    );
  });

  test(
    'Completed starts from the file and the director can change it',
    () async {
      await controller.chooseAndRead();
      controller.toggle(1);
      expect(controller.completed(1), isTrue);
      controller.setCompleted(1, false);
      expect(controller.completed(1), isFalse);
      // Choosing again keeps the director's answer.
      controller.toggle(1);
      controller.toggle(1);
      expect(controller.completed(1), isFalse);
    },
  );

  test('restores pilots, stamps them, then each competition', () async {
    await controller.chooseAndRead();
    controller.setAll(true);
    controller.setCompleted(2, false);
    await controller.continueToPilots();
    controller.continueToConfirm();
    expect(controller.step, CompetitionImportStep.confirm);
    final summary = controller.summary;
    expect(summary.created, 2);
    expect(summary.replaced, 0);
    expect(summary.flights, 6);
    expect(summary.completed, 1);
    expect(summary.newPilots, 2);
    expect(controller.needsReplaceConfirmation, isFalse);

    await controller.apply();

    expect(controller.step, CompetitionImportStep.done);
    expect(store.applied, hasLength(1));
    expect(store.stamped.single.map((e) => e.sourcePilotNo), [1, 2]);
    expect(store.stamped.single.every((e) => e.created), isTrue);
    expect(store.restored.map((i) => i.compNo), [1, 2]);
    expect(store.restored.map((i) => i.completed), [true, false]);
    // Both competitions get Ada's profile, the shared pilot.
    expect(store.restored[0].profiles[1], store.restored[1].profiles[1]);
    expect(controller.results, everyElement(isA<CompetitionRestored>()));
    expect(controller.anyImported, isTrue);
    expect(controller.importedContestIds, hasLength(2));
  });

  test('a pilot the director leaves out is reported, not written', () async {
    await controller.chooseAndRead();
    controller.toggle(1);
    await controller.continueToPilots();
    final bo = controller.pilots.review!.matches.indexWhere(
      (m) => m.draft.lastName == 'Nilsson',
    );
    controller.pilots.choose(bo, PilotImportChoice.skip);
    await controller.apply();

    final result = controller.results.single as CompetitionRestored;
    expect(result.skippedParticipants, [2]);
    expect(store.stamped.single.map((e) => e.sourcePilotNo), [1]);
  });

  test('one competition failing leaves the others', () async {
    store.answers[1] = const CompetitionRestoreFailed(
      1,
      RestoreFailure.comparisonFailed,
      mismatchCount: 2,
      mismatches: [
        RestoreMismatch(
          roundNo: 1,
          groupNo: 1,
          sourcePilotNo: 2,
          reflightNo: 0,
        ),
      ],
    );
    store.throwsFor.add(2);
    await controller.chooseAndRead();
    controller.setAll(true);
    await controller.continueToPilots();
    await controller.apply();

    expect(controller.step, CompetitionImportStep.done);
    final byNo = {for (final r in controller.results) r.sourceCompNo: r};
    expect(
      (byNo[1] as CompetitionRestoreFailed).code,
      RestoreFailure.comparisonFailed,
    );
    expect((byNo[2] as CompetitionRestoreFailed).code, RestoreFailure.failed);
    expect(controller.anyImported, isFalse);
  });

  group('a competition imported before', () {
    test('replaces its contest and needs confirming after changes', () async {
      final earlier = earlierImport(
        changes: const ContestChanges(scoresEntered: 3),
      );
      store.targets[1] = earlier;
      await controller.chooseAndRead();
      controller.toggle(1);
      expect(controller.replacedBy(1)!.contestId, earlier.contestId);
      expect(controller.needsReplaceConfirmation, isTrue);
      expect(controller.summary.replaced, 1);

      controller.setReplaceConfirmed(true);
      await controller.continueToPilots();
      await controller.apply();

      final call = store.restored.single;
      expect(call.confirmedReplace, isTrue);
      expect(call.updateContestId, isNull);
      expect(
        (controller.results.single as CompetitionRestored).updated,
        isTrue,
      );
    });

    test('with nothing changed since, no confirmation is asked', () async {
      store.targets[1] = earlierImport();
      await controller.chooseAndRead();
      controller.toggle(1);
      expect(controller.needsReplaceConfirmation, isFalse);
    });

    test('content already restored counts as unchanged', () async {
      await controller.chooseAndRead();
      final plan = controller.planOf(1)!;
      store.targets[1] = earlierImport(
        storedHash: plan.contentHash,
        storedCompleted: true,
      );
      controller.dispose();
      controller = build();
      await controller.chooseAndRead();
      controller.toggle(1);
      expect(controller.summary.unchanged, 1);
      expect(controller.summary.replaced, 0);
    });

    test('a published or synced contest cannot be replaced', () async {
      store.targets[1] = earlierImport(published: true);
      store.targets[2] = earlierImport(synced: true, name: 'Autumn Open');
      await controller.chooseAndRead();

      expect(controller.refusalOf(1), RestoreRefusal.resultsPublished);
      expect(controller.refusalOf(2), RestoreRefusal.contestSynced);
      expect(controller.importable, isEmpty);
      controller.setAll(true);
      expect(controller.chosen, isEmpty);
    });

    test(
      'a number match is a new contest until the director says no',
      () async {
        final earlier = earlierImport(kind: RestoreTargetKind.numberMatch);
        store.targets[1] = earlier;
        await controller.chooseAndRead();
        controller.toggle(1);
        expect(controller.replacedBy(1), isNull);
        expect(controller.summary.created, 1);

        controller.setSameAs(1, true);
        expect(controller.replacedBy(1)!.contestId, earlier.contestId);
        await controller.continueToPilots();
        await controller.apply();
        expect(store.restored.single.updateContestId, earlier.contestId);
      },
    );

    test('a failing lookup leaves the competition new', () async {
      await controller.chooseAndRead();
      expect(controller.targetOf(1), isNull);
      expect(controller.replacedBy(1), isNull);
    });
  });

  test('a file that cannot be read fails with the reason', () async {
    controller.dispose();
    controller = build(read: (_) async => throw StateError('no reader'));
    await controller.chooseAndRead();

    expect(controller.step, CompetitionImportStep.failed);
    expect(controller.error, isA<StateError>());
    expect(controller.canReviewAgain, isFalse);
  });

  test('a failure while mapping reaches the wizard as an error', () async {
    controller.dispose();
    controller = build(mapFile: (_) async => throw StateError('bad file'));
    await controller.chooseAndRead();

    expect(controller.step, CompetitionImportStep.failed);
    expect(controller.error, isA<StateError>());
  });

  test('cancelling while the file is read drops its result', () async {
    controller.dispose();
    final release = Future<GliderScoreImportResult>.delayed(
      const Duration(milliseconds: 20),
      competitionsSnapshot,
    );
    controller = build(read: (_) => release);
    final reading = controller.chooseAndRead();
    await Future<void>.delayed(Duration.zero);
    expect(controller.step, CompetitionImportStep.reading);
    controller.cancelReading();
    await reading;

    expect(controller.step, CompetitionImportStep.idle);
    expect(controller.listed, isEmpty);
  });

  test('cancelling while the file is mapped drops the plans', () async {
    controller.dispose();
    final mapping = Completer<MappedGliderScoreFile>();
    controller = build(mapFile: (_) => mapping.future);
    final reading = controller.chooseAndRead();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    controller.cancelReading();
    mapping.complete(mapGliderScoreFile(competitionsSnapshot()));
    await reading;

    expect(controller.step, CompetitionImportStep.idle);
    expect(controller.listed, isEmpty);
    expect(store.restored, isEmpty);
  });

  test('a participant edited during the review fails the apply', () async {
    store.applyError = StaleRevisionError(
      entityType: 'ParticipantProfile',
      entityId: Id.create(),
      expectedRevision: 0,
      storedRevision: 1,
    );
    await controller.chooseAndRead();
    controller.toggle(1);
    await controller.continueToPilots();
    await controller.apply();

    expect(controller.step, CompetitionImportStep.failed);
    expect(controller.changedDuringReview, isTrue);
    expect(store.restored, isEmpty);

    store.applyError = null;
    await controller.reviewAgain();
    expect(controller.step, CompetitionImportStep.pilots);
  });

  test('a file with nothing importable cannot go on', () async {
    controller.dispose();
    controller = build(
      read: (_) async => GliderScoreImportResult(
        id: Id.create(),
        sourceDbFile: 'x.mdb',
        tables: [
          GliderScoreTable(
            name: 'Comps',
            rows: const [
              {
                'CompNo': 3,
                'CompName': 'F3J only',
                'GSCompClass': 'F3J',
                'CompDate': '06/14/26 00:00:00',
              },
            ],
            rowCount: 1,
            rowCapExceeded: false,
          ),
        ],
      ),
    );
    await controller.chooseAndRead();

    expect(controller.importable, isEmpty);
    controller.setAll(true);
    expect(controller.chosen, isEmpty);
    await controller.continueToPilots();
    expect(controller.step, CompetitionImportStep.competitions);
  });

  test('choosing a different file drops the earlier choices', () async {
    await controller.chooseAndRead();
    controller.setAll(true);
    controller.setSameAs(1, true);
    await controller.chooseAndRead();

    expect(controller.chosen, isEmpty);
    expect(controller.isSameAs(1), isFalse);
  });
}
