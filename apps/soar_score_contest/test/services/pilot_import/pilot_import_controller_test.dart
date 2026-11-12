import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/pilot_import/pilot_import.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/pilot_import_fakes.dart';

void main() {
  final rows = <Map<String, Object?>>[
    {
      'PilotNo': 1,
      'FirstName': 'Nina',
      'LastName': 'Newcomer',
      'Email': 'n@x.test',
    },
    {
      'PilotNo': 2,
      'FirstName': 'Erin',
      'LastName': 'Existing',
      'Email': 'e@x.test',
      'Club': 'New Club',
    },
    {'PilotNo': 3, 'FirstName': 'Sam', 'LastName': 'Samename'},
    {'PilotNo': 4, 'FirstName': 'Test', 'LastName': 'ZZUser'},
  ];
  late FakePilotImportStore store;
  late ParticipantProfile erin;
  late ParticipantProfile sam;
  late List<String> reads;

  PilotImportController controller({
    String? chosen = r'C:\gs\Contest.mdb',
    Future<GliderScoreImportResult> Function(String)? read,
  }) => PilotImportController(
    store: store,
    readFile:
        read ??
        (path) async {
          reads.add(path);
          return pilotsSnapshot(rows);
        },
    files: GliderScoreFiles(choose: () async => chosen),
  );

  setUp(() {
    erin = profile(first: 'Erin', last: 'Existing', email: 'E@x.test');
    sam = profile(first: 'Sam', last: 'Samename');
    store = FakePilotImportStore([erin, sam]);
    reads = [];
  });

  test('a cancelled chooser reads nothing', () async {
    final c = controller(chosen: null);
    expect(await c.chooseAndRead(), isFalse);
    expect(c.step, PilotImportStep.idle);
    expect(reads, isEmpty);
  });

  test('a remembered name-only pilot is preselected', () async {
    final draft = const PilotDraft(
      sourcePilotNo: 3,
      firstName: 'Sam',
      lastName: 'Samename',
    );
    final now = DateTime.utc(2026);
    store.links.add(
      PilotImportLink(
        id: Id.create(),
        ownerAccountId: sam.ownerAccountId,
        sourcePilotNo: 3,
        participantProfileId: sam.id,
        sourceValues: PilotImportMatcher.sourceValues(draft),
        createdAt: now,
        updatedAt: now,
      ),
    );
    final c = controller();
    await c.chooseAndRead();
    expect(c.review!.matches[2].remembered, isTrue);
    expect(c.selections[2].targetProfileId, sam.id);
    expect(c.selections[2].choice, PilotImportChoice.update);
  });

  group('a pilot whose link is under review', () {
    PilotImportLink linkTo(ParticipantProfile target, int number) {
      final now = DateTime.utc(2026);
      return PilotImportLink(
        id: Id.create(),
        ownerAccountId: target.ownerAccountId,
        sourcePilotNo: number,
        participantProfileId: target.id,
        sourceValues: PilotImportMatcher.sourceValues(
          PilotDraft(
            sourcePilotNo: number,
            firstName: target.firstName,
            lastName: target.lastName,
          ),
        ),
        createdAt: now,
        updatedAt: now,
      );
    }

    test('is held back and cannot be chosen', () async {
      store.links.add(linkTo(sam, 3));
      store.underReview = {3};
      final c = controller();
      await c.chooseAndRead();

      final held = c.review!.matches[2];
      expect(held.linkReview, isTrue);
      expect(held.remembered, isFalse);
      expect(held.candidateIds, isEmpty);
      expect(c.selections[2].choice, PilotImportChoice.skip);

      c.choose(2, PilotImportChoice.update, target: sam.id);
      c.choose(2, PilotImportChoice.add);
      expect(c.selections[2].choice, PilotImportChoice.skip);
    });

    test('lets the other pilots of the file go ahead', () async {
      store.links.add(linkTo(sam, 3));
      store.underReview = {3};
      final c = controller();
      await c.chooseAndRead();

      await c.apply();

      expect(c.step, PilotImportStep.done);
      final saved = store.applied.single;
      expect(
        saved
            .where((s) => s.choice != PilotImportChoice.skip)
            .map((s) => s.match.draft.sourcePilotNo),
        containsAll([1, 2]),
      );
      expect(
        saved.singleWhere((s) => s.match.draft.sourcePilotNo == 3).choice,
        PilotImportChoice.skip,
      );
    });

    test('stops an import that was reviewed before the review began', () async {
      final c = controller();
      await c.chooseAndRead();
      store.applyError = PilotImportLinkReviewError({3});

      await c.apply();

      expect(c.step, PilotImportStep.failed);
      expect(c.linkReviewPending, isTrue);
      expect(c.changedDuringReview, isTrue);
    });
  });

  group('another installation manages the remembered links', () {
    setUp(() => store.managedElsewhere = true);

    PilotImportLink linkTo(ParticipantProfile p, int number) => PilotImportLink(
      id: Id.create(),
      ownerAccountId: p.ownerAccountId,
      sourcePilotNo: number,
      participantProfileId: p.id,
      sourceValues: const {},
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

    test('nothing is saved until the one-time import is chosen', () async {
      store.links.add(linkTo(sam, 3));
      final c = controller();
      await c.chooseAndRead();

      expect(c.linksManagedElsewhere, isTrue);
      expect(c.needsOneTimeChoice, isTrue);
      // The remembered links are not reused on this computer.
      expect(c.review!.matches.any((m) => m.remembered), isFalse);

      await c.apply();

      expect(c.step, PilotImportStep.failed);
      expect(c.managedElsewhereRefused, isTrue);
      expect(store.applied, isEmpty);

      await c.importWithoutRememberedLinks();
      expect(c.needsOneTimeChoice, isFalse);
    });

    test(
      'management that changed during the review is checked again',
      () async {
        final c = controller();
        store.managedElsewhere = false;
        await c.chooseAndRead();
        expect(c.needsOneTimeChoice, isFalse);

        store.managedElsewhere = true;
        await c.apply();

        expect(c.managedElsewhereRefused, isTrue);
        expect(store.applied, isEmpty);
      },
    );

    test('importing without remembered links confirms every match', () async {
      store.links.add(linkTo(sam, 3));
      final c = controller();
      await c.chooseAndRead();

      await c.importWithoutRememberedLinks();

      expect(c.importingWithoutLinks, isTrue);
      final matches = c.review!.matches;
      expect(matches.any((m) => m.remembered), isFalse);
      // The pilot with a participant to match waits for the director.
      for (var i = 0; i < matches.length; i++) {
        if (matches[i].candidateIds.isNotEmpty) {
          expect(c.selections[i].choice, PilotImportChoice.skip);
        }
      }
      c.choose(1, PilotImportChoice.update);
      expect(c.selections[1].choice, PilotImportChoice.update);
    });

    test('saves without remembering links', () async {
      final c = controller();
      await c.chooseAndRead();
      await c.importWithoutRememberedLinks();

      await c.apply();

      expect(c.step, PilotImportStep.done);
      expect(store.rememberedLinks, [false]);
    });

    test('a pilot whose link is under review stays held back', () async {
      store.links.add(linkTo(sam, 3));
      store.underReview = {3};
      final c = controller();
      await c.chooseAndRead();
      await c.importWithoutRememberedLinks();

      final held = c.review!.matches[2];
      expect(held.linkReview, isTrue);
      expect(c.selections[2].choice, PilotImportChoice.skip);
    });
  });

  test('an import by the managing installation remembers its links', () async {
    final c = controller();
    await c.chooseAndRead();

    await c.apply();

    expect(c.linksManagedElsewhere, isFalse);
    expect(store.rememberedLinks, [true]);
  });

  test('reading builds a review with sensible defaults', () async {
    final c = controller();
    expect(await c.chooseAndRead(), isTrue);
    expect(c.step, PilotImportStep.review);
    expect(c.fileName, 'Contest.mdb');
    expect(reads, [r'C:\gs\Contest.mdb']);
    expect(c.review!.draft.excludedTestUsers, 1);
    // new pilot added, exact match updated, name-only match left for a person
    expect(c.plan, (added: 1, updated: 1, unchanged: 0, skipped: 1));
    final kinds = [for (final m in c.review!.matches) m.kind];
    expect(kinds, [
      PilotMatchKind.newPilot,
      PilotMatchKind.exact,
      PilotMatchKind.likely,
    ]);
  });

  test('choosing for a maybe changes the plan', () async {
    final c = controller();
    await c.chooseAndRead();
    c.choose(2, PilotImportChoice.add);
    expect(c.plan.added, 2);
    c.choose(2, PilotImportChoice.update);
    expect(c.selections[2].targetProfileId, sam.id);
    expect(c.plan.updated, 2);
    c.choose(0, PilotImportChoice.skip);
    expect(c.plan.added, 0);
  });

  test('applying saves the choices and reports the outcome', () async {
    final c = controller();
    await c.chooseAndRead();
    await c.apply();
    expect(c.step, PilotImportStep.done);
    expect(c.outcome!.added, hasLength(1));
    expect(c.outcome!.updated, hasLength(1));
    expect(c.outcome!.skipped, 1);
    expect(store.applied, hasLength(1));
  });

  test('a read failure is reported', () async {
    final c = controller(read: (_) async => throw StateError('no helper'));
    await c.chooseAndRead();
    expect(c.step, PilotImportStep.failed);
    expect(c.error, isA<StateError>());
    expect(c.changedDuringReview, isFalse);
  });

  test(
    'a stale participant asks for a new review from the same file',
    () async {
      final c = controller();
      await c.chooseAndRead();
      store.applyError = StaleRevisionError(
        entityType: 'ParticipantProfile',
        entityId: erin.id,
        expectedRevision: 0,
        storedRevision: 1,
      );
      await c.apply();
      expect(c.step, PilotImportStep.failed);
      expect(c.changedDuringReview, isTrue);

      store.applyError = null;
      store.profiles = [
        profile(
          first: 'Erin',
          last: 'Existing',
          email: 'e@x.test',
          revision: 1,
        ),
      ];
      await c.reviewAgain();
      expect(c.step, PilotImportStep.review);
      expect(reads, hasLength(1), reason: 'the file is not read again');
    },
  );

  test('the review revisions of every participant go to the store', () async {
    final c = controller();
    await c.chooseAndRead();
    await c.apply();
    expect(store.appliedRevisions.single, {
      erin.id: erin.revision,
      sam.id: sam.revision,
    });
  });

  test('a changed participant list asks for a new review', () async {
    final c = controller();
    await c.chooseAndRead();
    store.applyError = PilotImportReviewChangedError([erin.id]);
    await c.apply();
    expect(c.step, PilotImportStep.failed);
    expect(c.changedDuringReview, isTrue);
  });

  test('a file chooser that throws is a failure that can be retried', () async {
    var calls = 0;
    final c = PilotImportController(
      store: store,
      readFile: (_) async => pilotsSnapshot(rows),
      files: GliderScoreFiles(
        choose: () async {
          calls++;
          if (calls == 1) throw StateError('plugin missing');
          return r'C:\gs\Contest.mdb';
        },
      ),
    );
    expect(await c.chooseAndRead(), isTrue);
    expect(c.step, PilotImportStep.failed);
    expect(c.error, isA<StateError>());
    expect(c.canChooseAgain, isTrue);
    expect(c.changedDuringReview, isFalse);

    await c.reviewAgain();
    expect(c.step, PilotImportStep.review);
  });
}
