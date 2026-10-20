import 'package:logging/logging.dart';
import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';

void main() => forEachBackend(_tests);

/// Who may send what: versions, registered installations, the single
/// administration installation, deletions and the contest state.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late core.Id contestId;
  late core.ContestScopeKey scope;

  setUp(() async {
    harness = await AcceptorHarness.open(backend);
    contestId = await harness.drawContestOnClient();
    scope = core.ContestScopeKey(contestId);
  });
  tearDown(() => harness.close());

  Matcher refusal(String code, int status) => throwsA(
    isA<core.SyncRefusal>()
        .having((e) => e.code, 'code', code)
        .having((e) => e.statusCode, 'status', status),
  );

  group('versions', () {
    test(
      'a protocol outside the range is told to update, first of all',
      () async {
        expect(
          () => harness.exchange(
            scope,
            installation: core.Id.create(),
            protocolVersion: 2,
          ),
          refusal('unsupported_protocol_version', 426),
        );
      },
    );

    test('a schema below the minimum is told to update', () async {
      expect(
        () => harness.exchange(scope, schemaVersion: 0),
        refusal('schema_too_old', 426),
      );
    });

    test('a schema above the maximum is told to wait', () async {
      expect(
        () => harness.exchange(scope, schemaVersion: 2),
        refusal('unsupported_protocol_version', 409),
      );
    });

    test('nothing is processed for a client out of range', () async {
      final sent = await harness.outbox(core.DirectorScopeKey(harness.account));
      await expectLater(
        harness.exchange(
          core.DirectorScopeKey(harness.account),
          mutations: sent,
          schemaVersion: 0,
        ),
        throwsA(isA<core.SyncRefusal>()),
      );
      expect(await harness.serverMutationCount(), 0);
    });
  });

  group('installations', () {
    test('an unregistered installation is told to register', () async {
      expect(
        () => harness.exchange(scope, installation: core.Id.create()),
        throwsA(
          isA<core.ForbiddenError>().having(
            (e) => e.code,
            'code',
            'unknown_installation',
          ),
        ),
      );
    });

    test('a revoked installation cannot synchronize', () async {
      await harness.installations.revoke(
        accountId: harness.account,
        id: harness.installationA,
      );

      expect(
        () => harness.exchange(scope),
        refusal('inactive_installation', 403),
      );
    });

    test('registering again returns the stored installation', () async {
      final first = await harness.register(harness.installationB, 'Tablet');
      final again = await harness.register(harness.installationB, 'Renamed');

      expect(again, first);
      expect(await harness.installations.list(harness.account), hasLength(2));
    });

    test('another account cannot use or revoke the installation', () async {
      final other = core.Id.create();
      await harness.serverRepository.accountRepository.save(
        core.Account(
          id: other,
          firstName: 'Sam',
          lastName: 'Other',
          email: 'sam@example.org',
          kind: core.AccountKind.registered,
          createdAt: DateTime.utc(2026, 10, 1),
          updatedAt: DateTime.utc(2026, 10, 1),
        ),
      );

      await expectLater(
        harness.exchange(scope, as: other),
        throwsA(isA<core.ForbiddenError>()),
      );
      await expectLater(
        harness.installations.revoke(
          accountId: other,
          id: harness.installationA,
        ),
        throwsA(isA<core.ForbiddenError>()),
      );
      await expectLater(
        harness.installations.register(
          accountId: other,
          id: harness.installationA,
          label: 'Stolen',
          platform: core.Platform.windows,
        ),
        throwsA(isA<core.ForbiddenError>()),
      );
    });

    test(
      'a director cannot synchronize another director or their contest',
      () async {
        await harness.uploadAll(contestId);
        final other = core.Id.create();
        await harness.serverRepository.accountRepository.save(
          core.Account(
            id: other,
            firstName: 'Sam',
            lastName: 'Other',
            email: 'sam@example.org',
            kind: core.AccountKind.registered,
            createdAt: DateTime.utc(2026, 10, 1),
            updatedAt: DateTime.utc(2026, 10, 1),
          ),
        );
        final theirs = core.Id.create();
        await harness.installations.register(
          accountId: other,
          id: theirs,
          label: 'Theirs',
          platform: core.Platform.windows,
        );

        await expectLater(
          harness.exchange(scope, installation: theirs, as: other),
          throwsA(
            isA<core.ForbiddenError>().having(
              (e) => e.code,
              'code',
              'not_director',
            ),
          ),
        );
        await expectLater(
          harness.exchange(
            core.DirectorScopeKey(harness.account),
            installation: theirs,
            as: other,
          ),
          throwsA(
            isA<core.ForbiddenError>().having(
              (e) => e.code,
              'code',
              'not_owner',
            ),
          ),
        );
      },
    );
  });

  group('mutations', () {
    setUp(() async {
      await harness.uploadAll(contestId);
    });

    test('derived values, participants and wrong scopes are refused', () async {
      final profile =
          (await harness.server.stores.of('ParticipantProfile').all()).first
              as core.ParticipantProfile;
      final stored = (await harness.stored('Contest', contestId))!;

      final records = <LogRecord>[];
      final subscription = Logger.root.onRecord.listen(records.add);
      addTearDown(subscription.cancel);
      hierarchicalLoggingEnabled = false;
      final level = Logger.root.level;
      Logger.root.level = Level.ALL;
      addTearDown(() => Logger.root.level = level);

      final out = await harness.exchange(
        scope,
        mutations: [
          harness.save('ParticipantProfile', profile.toJson()),
          harness.save(
            'Contest',
            {...stored, 'name': 'By a participant'},
            base: stored['revision']! as int,
            authority: core.Authority.participant,
          ),
          harness.save('Contest', {
            ...stored,
            'owner_account_id': core.Id.create().value,
          }, base: stored['revision']! as int),
        ],
      );

      expect(out.results.map((r) => r.reasonCode), [
        'invalid_payload',
        'unauthorized',
        'unauthorized',
      ]);
      expect(
        (await harness.stored('Contest', contestId))!['name'],
        stored['name'],
      );

      final warnings = records
          .where((r) => r.loggerName == 'SyncLog' && r.level == Level.WARNING)
          .map((r) => r.message)
          .toList();
      expect(warnings, hasLength(2));
      expect(warnings[0], contains('authority=participant'));
      expect(warnings[1], contains('owner_account_id is'));
      expect(warnings[1], contains('reason=unauthorized'));
    });

    test(
      'a change from an installation without authority is rejected',
      () async {
        await harness.register(harness.installationB, 'Tablet');
        final stored = (await harness.stored('Contest', contestId))!;
        final edit = harness.save('Contest', {
          ...stored,
          'name': 'From B',
        }, base: stored['revision']! as int);

        final out = await harness.exchange(
          scope,
          installation: harness.installationB,
          mutations: [edit],
        );

        expect(out.results.single.outcome, core.MutationOutcome.rejected);
        expect(out.results.single.reasonCode, 'inactive_installation');
        expect(
          (await harness.stored('Contest', contestId))!['name'],
          stored['name'],
        );
      },
    );

    test('an activation moves authority and ends the previous one', () async {
      await harness.register(harness.installationB, 'Tablet');
      final stored = (await harness.stored('Contest', contestId))!;
      final base = stored['revision']! as int;

      final activation = await harness.installations.activate(
        accountId: harness.account,
        contestId: contestId,
        installationId: harness.installationB,
        kind: core.ActivationKind.replacement,
      );

      final all = await harness
          .serverRepository
          .installationActivationRepository
          .listForContest(contestId);
      expect(all.where((a) => a.isOpen), [activation]);
      expect(all, hasLength(2));
      final fromB = await harness.exchange(
        scope,
        installation: harness.installationB,
        mutations: [
          harness.save('Contest', {...stored, 'name': 'From B'}, base: base),
        ],
      );
      final fromA = await harness.exchange(
        scope,
        mutations: [
          harness.save('Contest', {...stored, 'name': 'From A'}, base: base),
        ],
      );
      expect(fromB.results.single.outcome, core.MutationOutcome.accepted);
      expect(fromA.results.single.reasonCode, 'inactive_installation');
      expect(
        await harness.installations.activate(
          accountId: harness.account,
          contestId: contestId,
          installationId: harness.installationB,
          kind: core.ActivationKind.replacement,
        ),
        activation,
      );
    });

    test(
      'reclaiming needs the installation to have pulled everything',
      () async {
        await harness.register(harness.installationB, 'Tablet');
        await harness.installations.activate(
          accountId: harness.account,
          contestId: contestId,
          installationId: harness.installationB,
          kind: core.ActivationKind.replacement,
        );
        final stored = (await harness.stored('Contest', contestId))!;
        final edit = await harness.exchange(
          scope,
          installation: harness.installationB,
          mutations: [
            harness.save('Contest', {
              ...stored,
              'name': 'From B',
            }, base: stored['revision']! as int),
          ],
        );
        Future<core.InstallationActivation> reclaim() =>
            harness.installations.activate(
              accountId: harness.account,
              contestId: contestId,
              installationId: harness.installationA,
              kind: core.ActivationKind.reclaim,
            );

        await expectLater(reclaim(), refusal('reclaim_requires_sync', 409));
        await harness.exchange(scope, after: edit.serverSequence);
        final activation = await reclaim();

        expect(activation.installationId, harness.installationA);
        final open =
            (await harness.serverRepository.installationActivationRepository
                    .listForContest(contestId))
                .where((a) => a.isOpen);
        expect(open.map((a) => a.installationId), [harness.installationA]);
      },
    );

    test(
      'only the director activates, and not a revoked installation',
      () async {
        await harness.register(harness.installationB, 'Tablet');
        await harness.installations.revoke(
          accountId: harness.account,
          id: harness.installationB,
        );

        await expectLater(
          harness.installations.activate(
            accountId: harness.account,
            contestId: contestId,
            installationId: harness.installationB,
            kind: core.ActivationKind.replacement,
          ),
          refusal('inactive_installation', 403),
        );
        await expectLater(
          harness.installations.activate(
            accountId: core.Id.create(),
            contestId: contestId,
            installationId: harness.installationA,
            kind: core.ActivationKind.replacement,
          ),
          throwsA(isA<core.ForbiddenError>()),
        );
        await expectLater(
          harness.installations.activate(
            accountId: harness.account,
            contestId: core.Id.create(),
            installationId: harness.installationA,
            kind: core.ActivationKind.replacement,
          ),
          throwsA(isA<core.EntityNotFoundError>()),
        );
      },
    );

    test(
      'a deletion leaves a tombstone and later changes are refused',
      () async {
        final roles = RolesService(harness.clientRepository);
        final director = core.DirectorScopeKey(harness.account);
        final role = await roles.create(
          harness.account,
          core.Id.create(),
          'Timer',
          metadata: _meta('role-1', harness.account),
        );
        final created = await harness.outbox(director);
        final first = await harness.exchange(director, mutations: created);
        await harness.acknowledge(created, first.results);
        await roles.delete(
          harness.account,
          role.id,
          metadata: _meta('role-2', harness.account),
        );
        final deletion = await harness.outbox(director);

        final deleted = await harness.exchange(director, mutations: deletion);
        final later = await harness.exchange(
          director,
          mutations: [
            harness.save('Role', {
              ...(await _roleJson(harness, role)),
              'display_name': 'Late',
            }, base: role.revision),
          ],
        );

        expect(deleted.results.single.outcome, core.MutationOutcome.accepted);
        expect(await harness.stored('Role', role.id), isNull);
        final change = deleted.changes.last;
        expect(change.entityId, role.id);
        expect(change.payload, {'deleted': true});
        expect(later.results.single.outcome, core.MutationOutcome.rejected);
        expect(later.results.single.reasonCode, 'entity_deleted');
      },
    );
  });
}

core.MutationMetadata _meta(String id, core.Id actor) => core.MutationMetadata(
  clientMutationId: id,
  authority: core.Authority.director,
  clientTime: DateTime.utc(2026, 10, 14),
  actorId: actor,
);

Future<Map<String, Object?>> _roleJson(
  AcceptorHarness harness,
  core.Role role,
) async => role.toJson();
