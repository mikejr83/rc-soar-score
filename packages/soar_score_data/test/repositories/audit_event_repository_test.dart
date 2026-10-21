import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/example_rows.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  late Repository repository;

  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    repository = Repository(inst.db);
  });
  tearDown(() => inst.close());

  final examples = [
    for (final row in exampleRows('audit_event')) core.AuditEvent.fromJson(row),
  ];

  core.AuditEvent attempt(
    core.Id publicationId, {
    core.AuditOutcome outcome = core.AuditOutcome.success,
    DateTime? at,
  }) => core.AuditEvent(
    id: core.Id.create(),
    entityType: 'PublicationIdentity',
    entityId: publicationId,
    publicationId: publicationId,
    action: core.AuditAction.publicationAttempt,
    authority: core.Authority.director,
    serverTimestamp: at ?? DateTime.utc(2026, 10, 8, 12),
    outcome: outcome,
  );

  group('AuditEventRepository', () {
    test('an example event survives a round trip', () async {
      final example = examples.first;

      await repository.auditEventRepository.append(example);

      expect(
        await repository.auditEventRepository.findById(example.id),
        example,
      );
    });

    test(
      'a publication attempt is appended and listed by publication',
      () async {
        final publication = core.Id.create();
        final other = core.Id.create();
        final first = attempt(publication);
        final second = attempt(
          publication,
          outcome: core.AuditOutcome.rejected,
          at: DateTime.utc(2026, 10, 8, 13),
        );
        await repository.auditEventRepository.append(second);
        await repository.auditEventRepository.append(first);
        await repository.auditEventRepository.append(attempt(other));

        final listed = await repository.auditEventRepository.listForPublication(
          publication,
        );

        expect(listed, [first, second]);
      },
    );

    test(
      'contest events are listed newest first, by action and limit',
      () async {
        final contest = core.Id.create();
        core.AuditEvent event(
          core.AuditAction action,
          int hour, {
          core.Id? contestId,
        }) => core.AuditEvent(
          id: core.Id.create(),
          entityType: 'Contest',
          entityId: contest,
          contestId: contestId ?? contest,
          action: action,
          authority: core.Authority.director,
          serverTimestamp: DateTime.utc(2026, 10, 8, hour),
        );
        final first = event(core.AuditAction.stateTransition, 9);
        final second = event(core.AuditAction.scoreAttempt, 10);
        final third = event(core.AuditAction.stateTransition, 11);
        for (final e in [second, third, first]) {
          await repository.auditEventRepository.append(e);
        }
        await repository.auditEventRepository.append(
          event(
            core.AuditAction.stateTransition,
            12,
            contestId: core.Id.create(),
          ),
        );
        final audits = repository.auditEventRepository;

        expect(await audits.listForContest(contest), [third, second, first]);
        expect(
          await audits.listForContest(
            contest,
            action: core.AuditAction.stateTransition,
          ),
          [third, first],
        );
        expect(await audits.listForContest(contest, limit: 2), [third, second]);
        expect(await audits.listForContest(core.Id.create()), isEmpty);
      },
    );

    test('an unknown event is not found', () async {
      expect(
        await repository.auditEventRepository.findById(core.Id.create()),
        isNull,
      );
    });

    test('appending the same id twice is refused', () async {
      final event = attempt(core.Id.create());
      await repository.auditEventRepository.append(event);

      await expectLater(
        repository.auditEventRepository.append(event),
        throwsA(isA<core.AlreadyStoredError>()),
      );
    });
  });
}
