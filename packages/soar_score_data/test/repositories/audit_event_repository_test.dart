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
