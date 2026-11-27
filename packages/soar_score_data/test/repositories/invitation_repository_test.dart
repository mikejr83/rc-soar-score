import 'dart:async';

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

  group('redeem', () {
    final account = core.Id.create();
    final other = core.Id.create();
    final at = DateTime.utc(2026, 11, 25, 12);

    Future<core.Invitation> unredeemed() async => repo.save(
      variant(first, {
        'redeemed_by_account_id': null,
        'first_used_at': null,
        'last_used_at': null,
      }),
    );

    test('sets the redeemer and both times on the first open', () async {
      final stored = await unredeemed();

      final applied = await repo.redeem(
        stored.id,
        expectedRedeemer: null,
        newRedeemer: account,
        usedAt: at,
      );

      expect(applied, isTrue);
      final after = (await repo.findById(stored.id))!;
      expect(after.redeemedByAccountId, account);
      expect(after.firstUsedAt, at);
      expect(after.lastUsedAt, at);
    });

    test('keeps the first use and moves the last', () async {
      final stored = await unredeemed();
      await repo.redeem(
        stored.id,
        expectedRedeemer: null,
        newRedeemer: account,
        usedAt: at,
      );
      final later = at.add(const Duration(hours: 1));

      final applied = await repo.redeem(
        stored.id,
        expectedRedeemer: account,
        newRedeemer: other,
        usedAt: later,
      );

      expect(applied, isTrue);
      final after = (await repo.findById(stored.id))!;
      expect(after.redeemedByAccountId, other);
      expect(after.firstUsedAt, at);
      expect(after.lastUsedAt, later);
    });

    test('does nothing when the redeemer is not the expected one', () async {
      final stored = await unredeemed();
      await repo.redeem(
        stored.id,
        expectedRedeemer: null,
        newRedeemer: account,
        usedAt: at,
      );
      final before = (await repo.findById(stored.id))!;

      expect(
        await repo.redeem(
          stored.id,
          expectedRedeemer: null,
          newRedeemer: other,
          usedAt: at.add(const Duration(hours: 1)),
        ),
        isFalse,
      );
      expect(
        await repo.redeem(
          stored.id,
          expectedRedeemer: other,
          newRedeemer: other,
          usedAt: at.add(const Duration(hours: 1)),
        ),
        isFalse,
      );
      expect(await repo.findById(stored.id), before);
    });

    test('does nothing for an invitation that is no longer active', () async {
      final stored = await repo.save(
        variant(first, {
          'state': 'Replaced',
          'redeemed_by_account_id': null,
          'first_used_at': null,
          'last_used_at': null,
        }),
      );

      expect(
        await repo.redeem(
          stored.id,
          expectedRedeemer: null,
          newRedeemer: account,
          usedAt: at,
        ),
        isFalse,
      );
      expect((await repo.findById(stored.id))!.redeemedByAccountId, isNull);
    });

    test('leaves every other field as stored', () async {
      final stored = await unredeemed();

      await repo.redeem(
        stored.id,
        expectedRedeemer: null,
        newRedeemer: account,
        usedAt: at,
      );

      final after = (await repo.findById(stored.id))!;
      expect({
        ...after.toSyncJson(),
        'redeemed_by_account_id': null,
        'first_used_at': null,
        'last_used_at': null,
      }, stored.toSyncJson());
    });
  });

  group('redeem that needs the account\'s Confirmed link', () {
    final at = DateTime.utc(2026, 11, 27, 12);
    final link = core.ParticipantAccountLink.fromJson(
      exampleRows('participant_account_link').single,
    );

    Future<core.Invitation> unredeemed() async => repo.save(
      variant(first, {
        'redeemed_by_account_id': null,
        'first_used_at': null,
        'last_used_at': null,
      }),
    );

    Future<bool> redeemForLink(core.Invitation stored) => repo.redeem(
      stored.id,
      expectedRedeemer: null,
      newRedeemer: link.accountId,
      usedAt: at,
      requireConfirmedLinkOf: (
        profileId: link.participantProfileId,
        accountId: link.accountId,
      ),
    );

    test('applies while the link is Confirmed', () async {
      final stored = await unredeemed();

      expect(await redeemForLink(stored), isTrue);
      expect(
        (await repo.findById(stored.id))!.redeemedByAccountId,
        link.accountId,
      );
    });

    test('does nothing once the link ended, with no guest involved', () async {
      final stored = await unredeemed();
      final links = Repository(inst.db).participantAccountLinkRepository;
      await links.save(
        core.ParticipantAccountLink.fromJson({
          ...link.toJson(),
          'status': 'Ended',
          'ended_at': '2026-11-27T11:00:00.000Z',
        }),
      );

      expect(await redeemForLink(stored), isFalse);
      expect((await repo.findById(stored.id))!.redeemedByAccountId, isNull);
    });

    test('waits for an unlink in progress on another connection and then '
        'finds the link ended', () async {
      final stored = await unredeemed();
      final peer = await inst.reopen();
      addTearDown(peer.close);
      final peerLinks = Repository(peer.db).participantAccountLinkRepository;
      final ended = core.ParticipantAccountLink.fromJson({
        ...link.toJson(),
        'status': 'Ended',
        'ended_at': '2026-11-27T11:00:00.000Z',
      });

      // The peer holds the link row (its lock is taken before the release
      // callback runs) until the test lets it commit.
      final holding = Completer<void>();
      final commit = Completer<void>();
      final unlinking = peerLinks.saveReleasingInvitations(
        ended,
        releases: () async {
          holding.complete();
          await commit.future;
          return {};
        },
      );
      await holding.future;

      // Started while the peer's transaction is open: with no row lock it
      // would read the still-Confirmed link and apply at once.
      final redeeming = redeemForLink(stored);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      commit.complete();
      await unlinking;

      expect(await redeeming, isFalse);
      expect((await repo.findById(stored.id))!.redeemedByAccountId, isNull);
    });
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

  test('reports when each contest latest invitation was issued', () async {
    final latest = examples
        .where((i) => i.contestId == first.contestId)
        .map((i) => i.issuedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    expect(
      await repo.latestIssuedAtForContests([first.contestId, core.Id.create()]),
      {first.contestId: latest},
    );
    expect(await repo.latestIssuedAtForContests([]), isEmpty);
  });
}
