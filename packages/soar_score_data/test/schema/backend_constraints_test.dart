import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/example_entities.dart';
import '../support/example_rows.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    await loadExamples(inst);
  });
  tearDown(() => inst.close());

  Future<void> put(String entity, Map<String, Object?> row) =>
      inst.stores.of(entity).upsertJson(row);

  /// A copy of the first example row of [file] with a new id and [changes].
  Map<String, Object?> variant(
    String file, [
    Map<String, Object?> changes = const {},
  ]) => {...exampleRows(file).first, 'id': core.Id.create().value, ...changes};

  Future<void> rejects(String entity, Map<String, Object?> row) =>
      expectLater(put(entity, row), throwsA(anything));

  String id(String file, [int index = 0]) =>
      exampleRows(file)[index]['id']! as String;

  group('foreign keys', () {
    test('refuse an identity of an unknown account', () async {
      await rejects(
        'AccountIdentity',
        variant('account_identity', {
          'account_id': core.Id.create().value,
          'subject': 'unknown-account',
        }),
      );
    });

    test('refuse deleting an account that has an identity', () async {
      await expectLater(
        inst.db.customStatement(
          'DELETE FROM accounts WHERE id = '
          "'${exampleRows('account_identity').first['account_id']}'",
        ),
        throwsA(anything),
      );
    });

    test('deleting a contest leaves its publication, unlinked', () async {
      await inst.stores.of('Contest').remove(core.Id.parse(id('contest')));

      final row = await inst.stores
          .of('PublicationIdentity')
          .findJson(core.Id.parse(id('publication_identity')));
      expect(row, isNotNull);
      expect(row!['contest_id'], isNull);
      expect(await inst.count('publication_projections'), greaterThan(0));
    });

    test('deleting a contest keeps activations and cursors', () async {
      final activations = await inst.count('installation_activations');
      final cursors = await inst.count('sync_cursors');

      await inst.stores.of('Contest').remove(core.Id.parse(id('contest')));

      expect(await inst.count('installation_activations'), activations);
      expect(await inst.count('sync_cursors'), cursors);
    });

    test('deleting a contest removes its invitations', () async {
      expect(await inst.count('invitations'), greaterThan(0));

      await inst.stores.of('Contest').remove(core.Id.parse(id('contest')));

      expect(await inst.count('invitations'), 0);
    });
  });

  group('unique keys', () {
    test('an account email is unique', () async {
      await rejects(
        'Account',
        variant('account', {'email': 'dana@example.org'}),
      );
    });

    test('an account email is stored in lowercase', () async {
      await rejects(
        'Account',
        variant('account', {'email': 'New@Example.org'}),
      );
    });

    test('an identity is unique by issuer and subject', () async {
      await rejects('AccountIdentity', variant('account_identity'));
    });

    test('an account has one public profile', () async {
      await rejects('AccountPublicProfile', variant('account_public_profile'));
    });

    test('profiles with no account may repeat', () async {
      await put(
        'AccountPublicProfile',
        variant('account_public_profile', {'account_id': null}),
      );
      await put(
        'AccountPublicProfile',
        variant('account_public_profile', {'account_id': null}),
      );
    });

    test('a profile links to an account once', () async {
      await rejects(
        'ParticipantAccountLink',
        variant('participant_account_link'),
      );
    });

    test('an account has one directory entry', () async {
      await rejects(
        'ParticipantDirectoryEntry',
        variant('participant_directory_entry'),
      );
    });

    test('a projection revision is taken once per publication', () async {
      await rejects(
        'PublicationProjection',
        variant('publication_projection', {'client_mutation_id': 'other'}),
      );
    });

    test('a client mutation id publishes once per publication', () async {
      await rejects(
        'PublicationProjection',
        variant('publication_projection', {'projection_revision': 99}),
      );
    });

    test('a pilot key is taken once per publication', () async {
      await rejects(
        'PublicationParticipant',
        variant('publication_participant'),
      );
    });

    test('an invitation revision is taken once per participation', () async {
      await rejects(
        'Invitation',
        variant('invitation', {
          'state': 'Replaced',
          'client_mutation_id': 'invitation-revision-clash',
        }),
      );
    });

    test('a client mutation id issues once per contest', () async {
      await rejects(
        'Invitation',
        variant('invitation', {'invitation_revision': 9, 'state': 'Replaced'}),
      );
    });

    test('a cursor is kept once per installation and scope', () async {
      await rejects('SyncCursor', variant('sync_cursor'));
    });
  });

  group('partial unique indexes', () {
    test('exactly one account stands in for deleted users', () async {
      await put(
        'Account',
        variant('account', {'kind': 'deleted', 'email': null}),
      );
      await rejects(
        'Account',
        variant('account', {'kind': 'deleted', 'email': null}),
      );
    });

    test('a profile has one confirmed link', () async {
      await rejects(
        'ParticipantAccountLink',
        variant('participant_account_link', {'account_id': id('account', 3)}),
      );
    });

    test('an ended link does not count', () async {
      await put(
        'ParticipantAccountLink',
        variant('participant_account_link', {
          'account_id': id('account', 3),
          'status': 'Ended',
          'ended_at': '2026-10-18T10:00:00Z',
        }),
      );
    });

    test('a contest has one open activation', () async {
      await rejects(
        'InstallationActivation',
        variant('installation_activation'),
      );
    });

    test('an ended activation does not count', () async {
      await put(
        'InstallationActivation',
        variant('installation_activation', {
          'ended_at': '2026-10-18T10:00:00Z',
        }),
      );
    });

    test('a publication has one pending delist request', () async {
      final pending = variant('delist_request', {
        'state': 'pending',
        'decided_by': null,
        'decided_at': null,
        'decision_note': null,
      });
      await put('DelistRequest', pending);
      await rejects('DelistRequest', {
        ...pending,
        'id': core.Id.create().value,
      });
    });

    test('a participation has one active invitation', () async {
      await rejects(
        'Invitation',
        variant('invitation', {
          'invitation_revision': 2,
          'client_mutation_id': 'second-active',
        }),
      );
    });
  });

  group('checks', () {
    test('enumerated columns accept only their values', () async {
      await rejects('Account', variant('account', {'kind': 'visitor'}));
      await rejects(
        'Installation',
        variant('installation', {'platform': 'Mainframe'}),
      );
    });

    test('a cursor belongs to exactly one scope', () async {
      await rejects(
        'SyncCursor',
        variant('sync_cursor', {
          'installation_id': id('installation'),
          'owner_account_id': id('account'),
        }),
      );
      await rejects(
        'SyncCursor',
        variant('sync_cursor', {'contest_id': null, 'owner_account_id': null}),
      );
    });

    test('hidden results have a round and a time together', () async {
      await rejects(
        'PublicationIdentity',
        variant('publication_identity', {
          'results_hidden_through_round': 2,
          'results_hidden_at': null,
        }),
      );
    });

    test('a redacted participant keeps no details', () async {
      await rejects(
        'PublicationParticipant',
        variant('publication_participant', {
          'pilot_key': 'p_redacted',
          'redacted_at': '2026-10-20T00:00:00Z',
        }),
      );
    });

    test('a revoked invitation records when', () async {
      await rejects(
        'Invitation',
        variant('invitation', {
          'invitation_revision': 5,
          'state': 'Revoked',
          'revoked_at': null,
          'client_mutation_id': 'revoked-without-time',
        }),
      );
    });
  });
}
