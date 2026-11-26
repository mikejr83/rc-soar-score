import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/example_entities.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

/// In the example data these accounts hold what a guest holds: the first is
/// the actor of every attempt, audit event and mutation record, the second
/// opened the example invitation. Together they stand in for guests.
final _actor = core.Id.parse('019c0000-0000-7000-8000-000000000001');
final _opener = core.Id.parse('019c0000-0000-7000-8000-000000000002');
final _guests = [_actor, _opener];

void _tests(Backend backend) {
  late Installation inst;
  late Repository repository;
  late core.ParticipantAccountLinkRepository links;
  late core.Id pilot;

  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    await loadExamples(inst);
    repository = Repository(inst.db);
    links = repository.participantAccountLinkRepository;
    pilot = core.Id.create();
    await repository.accountRepository.save(
      core.Account(
        id: pilot,
        firstName: 'Pat',
        lastName: 'Pilot',
        kind: core.AccountKind.registered,
        createdAt: DateTime.utc(2026, 10, 1),
        updatedAt: DateTime.utc(2026, 10, 1),
      ),
    );
  });
  tearDown(() => inst.close());

  core.ParticipantAccountLink confirmed(core.Id profile, {int revision = 0}) =>
      core.ParticipantAccountLink(
        id: core.Id.create(),
        participantProfileId: profile,
        accountId: pilot,
        status: core.ParticipantLinkStatus.confirmed,
        origin: core.ParticipantLinkOrigin.invitationRedemption,
        createdAt: DateTime.utc(2026, 10, 2),
        confirmedAt: DateTime.utc(2026, 10, 2),
        revision: revision,
      );

  Future<Map<String, int>> held(Iterable<core.Id> accounts) async {
    final list = accounts.map((a) => "'${a.value}'").join(', ');
    Future<int> count(String table, String column) async =>
        (await inst.db
                .customSelect(
                  'SELECT COUNT(*) AS n FROM $table WHERE $column IN ($list)',
                )
                .getSingle())
            .read<int>('n');
    return {
      'attempts': await count('score_attempts', 'actor_id'),
      'invitations': await count('invitations', 'redeemed_by_account_id'),
      'audit': await count('audit_events', 'actor_id'),
      'mutations': await count('mutation_records', 'actor_id'),
    };
  }

  group('profile email lookup', () {
    test('ignores case and whitespace', () async {
      final profiles = repository.participantProfileRepository;
      expect(
        [
          for (final p in await profiles.listByEmail(' SAM@Example.ORG '))
            p.email,
        ],
        ['sam@example.org'],
      );
      expect(await profiles.listByEmail('nobody@example.org'), isEmpty);
    });
  });

  group('bulk reads', () {
    test('participations, invitations and links of several ids', () async {
      final profile = core.Id.parse('019c0000-0000-7000-8000-000000000020');
      final participations = await repository.contestParticipationRepository
          .listForProfiles([profile, core.Id.create()]);
      expect(participations, isNotEmpty);
      expect(
        participations.every((p) => p.participantProfileId == profile),
        isTrue,
      );
      expect(
        await repository.contestParticipationRepository.listForProfiles([]),
        isEmpty,
      );

      final invitations = await repository.invitationRepository
          .listForParticipations([for (final p in participations) p.id]);
      expect(invitations, isNotEmpty);
      expect(
        await repository.invitationRepository.listForParticipations([]),
        isEmpty,
      );

      expect(
        [
          for (final l in await links.listForProfiles([profile])) l.accountId,
        ],
        [core.Id.parse('019c0000-0000-7000-8000-000000000002')],
      );
      expect(await links.listForProfiles([core.Id.create()]), isEmpty);
    });
  });

  group('claimGuests', () {
    Future<core.ParticipantAccountLink> storedLink() =>
        links.save(confirmed(core.Id.create()));

    test(
      're-points what the guest holds and leaves the link as it was',
      () async {
        final link = await storedLink();
        final total = await held(_guests);

        expect(await links.claimGuests(link, guestAccountIds: _guests), isTrue);

        expect(await held(_guests), {for (final k in total.keys) k: 0});
        expect(await held([pilot]), total);
        expect(await links.findById(link.id), link);
      },
    );

    test('repeating it, or an unknown guest, changes nothing', () async {
      final link = await storedLink();
      await links.claimGuests(link, guestAccountIds: _guests);
      final claimed = await held([pilot]);

      expect(
        await links.claimGuests(
          link,
          guestAccountIds: [..._guests, core.Id.create(), pilot],
        ),
        isTrue,
      );

      expect(await held([pilot]), claimed);
    });

    test('claims nothing once the link has ended', () async {
      final link = await storedLink();
      await links.save(
        core.ParticipantAccountLink(
          id: link.id,
          participantProfileId: link.participantProfileId,
          accountId: link.accountId,
          status: core.ParticipantLinkStatus.ended,
          origin: link.origin,
          createdAt: link.createdAt,
          confirmedAt: link.confirmedAt,
          endedAt: DateTime.utc(2026, 10, 3),
          revision: link.revision,
        ),
      );
      final before = await held(_guests);

      expect(await links.claimGuests(link, guestAccountIds: _guests), isFalse);

      expect(await held(_guests), before);
    });

    test('claims nothing for a link that is not stored, or is another '
        "account's", () async {
      final before = await held(_guests);
      final link = await storedLink();
      final other = core.ParticipantAccountLink(
        id: link.id,
        participantProfileId: link.participantProfileId,
        accountId: core.Id.create(),
        status: core.ParticipantLinkStatus.confirmed,
        origin: link.origin,
        createdAt: link.createdAt,
        confirmedAt: link.confirmedAt,
      );

      expect(
        await links.claimGuests(
          confirmed(core.Id.create()),
          guestAccountIds: _guests,
        ),
        isFalse,
      );
      expect(await links.claimGuests(other, guestAccountIds: _guests), isFalse);
      expect(await held(_guests), before);
    });
  });

  group('saveClaimingGuests', () {
    test('stores the link and re-points everything the guest holds', () async {
      final before = await held(_guests);
      expect(before.values.every((n) => n > 0), isTrue, reason: '$before');
      final total = {for (final e in before.entries) e.key: e.value};

      final stored = await links.saveClaimingGuests(
        confirmed(core.Id.create()),
        guestAccountIds: _guests,
      );

      expect(await links.findById(stored.id), stored);
      expect(await held(_guests), {for (final k in total.keys) k: 0});
      expect(await held([pilot]), total);
    });

    test('repeating it, or an unknown guest, changes nothing', () async {
      final link = confirmed(core.Id.create());
      await links.saveClaimingGuests(link, guestAccountIds: _guests);
      final claimed = await held([pilot]);

      await links.saveClaimingGuests(
        (await links.findById(link.id))!,
        guestAccountIds: [..._guests, core.Id.create()],
      );

      expect(await held([pilot]), claimed);
    });

    test('with no guests only stores the link', () async {
      final before = await held(_guests);
      await links.saveClaimingGuests(
        confirmed(core.Id.create()),
        guestAccountIds: const [],
      );
      expect(await held(_guests), before);
    });

    test('a refused link leaves the guest\'s entries alone', () async {
      // The example profile already has a confirmed link to another account.
      final before = await held(_guests);
      await expectLater(
        links.saveClaimingGuests(
          confirmed(core.Id.parse('019c0000-0000-7000-8000-000000000020')),
          guestAccountIds: _guests,
        ),
        throwsA(anything),
      );
      expect(await held(_guests), before);
      expect(await held([pilot]), {for (final k in before.keys) k: 0});
    });

    test('a stale revision leaves the guest\'s entries alone', () async {
      final link = confirmed(core.Id.create());
      await links.save(link);
      final before = await held(_guests);
      await expectLater(
        links.saveClaimingGuests(
          core.ParticipantAccountLink(
            id: link.id,
            participantProfileId: link.participantProfileId,
            accountId: pilot,
            status: core.ParticipantLinkStatus.confirmed,
            origin: link.origin,
            createdAt: link.createdAt,
            confirmedAt: link.confirmedAt,
            revision: 7,
          ),
          guestAccountIds: _guests,
        ),
        throwsA(isA<core.StaleRevisionError>()),
      );
      expect(await held(_guests), before);
    });
  });

  group('saveReleasingInvitations', () {
    final invitationId = core.Id.parse('019c0000-0000-7000-8000-0000000000d2');

    test(
      'hands an invitation the account holds back, leaving attempts',
      () async {
        final link = await links.saveClaimingGuests(
          confirmed(core.Id.create()),
          guestAccountIds: _guests,
        );
        final attempts = (await held([pilot]))['attempts'];

        await links.saveReleasingInvitations(
          link,
          invitationToGuest: {invitationId: _opener},
        );

        final invitation = (await repository.invitationRepository.findById(
          invitationId,
        ))!;
        expect(invitation.redeemedByAccountId, _opener);
        expect((await held([pilot]))['attempts'], attempts);
      },
    );

    test('hands it to nobody when its guest account does not exist', () async {
      final link = await links.save(confirmed(core.Id.create()));
      await links.saveClaimingGuests(link, guestAccountIds: _guests);

      await links.saveReleasingInvitations(
        (await links.findById(link.id))!,
        invitationToGuest: {invitationId: core.Id.create()},
      );

      expect(
        (await repository.invitationRepository.findById(invitationId))!
            .redeemedByAccountId,
        isNull,
      );
    });

    test(
      'can hand it back to nobody, and skips one the account does not hold',
      () async {
        final link = await links.save(confirmed(core.Id.create()));
        // Held by the example account, not by the pilot: left as it is.
        await links.saveReleasingInvitations(
          link,
          invitationToGuest: {invitationId: null},
        );
        expect(
          (await repository.invitationRepository.findById(invitationId))!
              .redeemedByAccountId,
          _opener,
        );

        await links.saveClaimingGuests(
          (await links.findById(link.id))!,
          guestAccountIds: _guests,
        );
        await links.saveReleasingInvitations(
          (await links.findById(link.id))!,
          invitationToGuest: {invitationId: null},
        );
        expect(
          (await repository.invitationRepository.findById(invitationId))!
              .redeemedByAccountId,
          isNull,
        );
      },
    );
  });
}
