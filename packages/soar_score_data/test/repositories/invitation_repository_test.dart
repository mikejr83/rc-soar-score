import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/example_entities.dart';
import '../support/example_rows.dart';
import '../support/fixtures.dart';

void main() => forPostgresOnly(_tests);

void _tests(Backend backend) {
  late Installation inst;
  late core.InvitationRepository repo;

  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    await loadExamples(inst);
    repo = Repository(inst.db).invitationRepository;
  });
  tearDown(() => inst.close());

  final examples = [
    for (final row in exampleRows('invitation')) core.Invitation.fromJson(row),
  ];
  final first = examples.first;

  /// [base] with the given JSON fields replaced, credential included.
  core.Invitation variant(core.Invitation base, Map<String, Object?> changes) =>
      core.Invitation.fromJson({...base.toSyncJson(), ...changes});

  test('reads back every example invitation unchanged', () async {
    for (final invitation in examples) {
      expect(await repo.findById(invitation.id), invitation);
    }
    expect(await repo.findById(core.Id.create()), isNull);
  });

  test('finds by client mutation id within its contest', () async {
    expect(
      await repo.findByClientMutationId(
        contestId: first.contestId,
        clientMutationId: first.clientMutationId,
      ),
      first,
    );
    expect(
      await repo.findByClientMutationId(
        contestId: core.Id.create(),
        clientMutationId: first.clientMutationId,
      ),
      isNull,
    );
    expect(
      await repo.findByClientMutationId(
        contestId: first.contestId,
        clientMutationId: 'unknown',
      ),
      isNull,
    );
  });

  test('finds by the stored protected credential', () async {
    expect(
      await repo.findByProtectedCredential(first.protectedCredential.value),
      first,
    );
    expect(await repo.findByProtectedCredential('pbkdf2-sha256\$x'), isNull);
  });

  test('lists a participation and a contest', () async {
    expect(await repo.listForParticipation(first.contestParticipationId), [
      first,
    ]);
    expect(await repo.listForParticipation(core.Id.create()), isEmpty);
    expect(await repo.listForContest(first.contestId), examples);
    expect(await repo.listForContest(core.Id.create()), isEmpty);
  });

  test('save replaces by id without a mutation record', () async {
    final before = await inst.count('mutation_records');
    final revoked = variant(first, {
      'state': 'Revoked',
      'revoked_at': '2026-10-18T09:00:00Z',
    });

    await repo.save(revoked);

    expect(await repo.findById(first.id), revoked);
    expect(
      await repo.findActiveForParticipation(first.contestParticipationId),
      isNull,
    );
    expect(await inst.count('mutation_records'), before);
  });

  test('a replacement keeps the earlier revision stored', () async {
    final replaced = variant(first, {'state': 'Replaced'});
    final next = variant(first, {
      'id': core.Id.create().toString(),
      'invitation_revision': 2,
      'state': 'Active',
      'replaces_invitation_id': first.id.toString(),
      'redeemed_by_account_id': null,
      'first_used_at': null,
      'last_used_at': null,
      'protected_credential': 'pbkdf2-sha256\$600000\$bmV4dA\$bmV4dA',
      'client_mutation_id': 'replacement',
    });

    await repo.save(replaced);
    await repo.save(next);

    expect(await repo.listForParticipation(first.contestParticipationId), [
      replaced,
      next,
    ]);
    expect(
      await repo.findActiveForParticipation(first.contestParticipationId),
      next,
    );
  });

  test('the database refuses a second active invitation', () async {
    await expectLater(
      repo.save(
        variant(first, {
          'id': core.Id.create().toString(),
          'invitation_revision': 2,
          'client_mutation_id': 'second-active',
        }),
      ),
      throwsA(anything),
    );
  });

  test('the database refuses a repeated revision', () async {
    await expectLater(
      repo.save(
        variant(first, {
          'id': core.Id.create().toString(),
          'state': 'Replaced',
          'client_mutation_id': 'repeated-revision',
        }),
      ),
      throwsA(anything),
    );
  });

  test('the database refuses a repeated client mutation id', () async {
    await expectLater(
      repo.save(
        variant(first, {
          'id': core.Id.create().toString(),
          'invitation_revision': 9,
          'state': 'Replaced',
        }),
      ),
      throwsA(anything),
    );
  });
}
