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
