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
  }) => CompetitionImportController(
    store: store,
    readFile: read ?? (_) async => competitionsSnapshot(),
    files: GliderScoreFiles(choose: () async => chosenPath),
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
    final all = controller.draft!.contests;
    expect(all.map((c) => c.sourceCompNo), [1, 2, 3, 4]);
    expect(controller.importable.map((c) => c.sourceCompNo), [1, 2]);
    expect(controller.chosen, isEmpty);
    expect(
      all.singleWhere((c) => c.sourceCompNo == 3).status,
      ContestImportStatus.skipped,
    );
    expect(
      all.singleWhere((c) => c.sourceCompNo == 4).reason,
      ContestImportReason.noParticipants,
    );
  });

  test('a cancelled chooser changes nothing', () async {
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
    final names = [
      for (final m in controller.pilots.review!.matches) m.draft.lastName,
    ];
    expect(names, ['Lovelace']);

    controller.backToCompetitions();
    controller.toggle(1);
    await controller.continueToPilots();
    expect([
      for (final m in controller.pilots.review!.matches) m.draft.lastName,
    ], unorderedEquals(['Lovelace', 'Nilsson']));
  });

  test('applies pilots, stamps them, then writes each competition', () async {
    await controller.chooseAndRead();
    controller.setAll(true);
    await controller.continueToPilots();
    controller.continueToConfirm();
    expect(controller.step, CompetitionImportStep.confirm);
    expect(controller.plan.contests, 2);
    expect(controller.plan.newPilots, 2);

    await controller.apply();

    expect(controller.step, CompetitionImportStep.done);
    expect(store.applied, hasLength(1));
    expect(store.stamped.single.map((e) => e.sourcePilotNo), [1, 2]);
    expect(store.stamped.single.every((e) => e.created), isTrue);
    expect(store.imported.map((i) => i.$1), [1, 2]);
    // Both competitions get Ada's profile, the shared pilot.
    expect(store.imported[0].$2[1], store.imported[1].$2[1]);
    expect(controller.results, everyElement(isA<CompetitionImported>()));
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

    final result = controller.results.single as CompetitionImported;
    expect(result.skippedParticipants, [2]);
    expect(store.stamped.single.map((e) => e.sourcePilotNo), [1]);
  });

  test('one competition failing leaves the others', () async {
    store.answers[1] = const CompetitionImportFailed(
      1,
      CompetitionImportFailure.profileUnavailable,
    );
    store.throwsFor.add(2);
    await controller.chooseAndRead();
    controller.setAll(true);
    await controller.continueToPilots();
    await controller.apply();

    expect(controller.step, CompetitionImportStep.done);
    final byNo = {for (final r in controller.results) r.sourceCompNo: r};
    expect(byNo[1], isA<CompetitionImportFailed>());
    expect(
      (byNo[2] as CompetitionImportFailed).code,
      CompetitionImportFailure.failed,
    );
    expect(controller.anyImported, isFalse);
  });

  test('a repeat of a competition is shown as already imported', () async {
    store.answers[1] = CompetitionAlreadyImported(
      1,
      contestId: Id.create(),
      importedAt: DateTime.utc(2026, 11),
      importOperationId: Id.create(),
    );
    await controller.chooseAndRead();
    controller.toggle(1);
    await controller.continueToPilots();
    await controller.apply();

    expect(controller.results.single, isA<CompetitionAlreadyImported>());
    expect(controller.anyImported, isFalse);
  });

  test('a file that cannot be read fails with the reason', () async {
    controller.dispose();
    controller = build(read: (_) async => throw StateError('no reader'));
    await controller.chooseAndRead();

    expect(controller.step, CompetitionImportStep.failed);
    expect(controller.error, isA<StateError>());
    expect(controller.canReviewAgain, isFalse);
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
    expect(controller.draft, isNull);
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
    expect(store.imported, isEmpty);

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
}
