import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';
import 'acceptor_pilot_link_support.dart';

void main() => forEachBackend(_tests);

/// One installation manages the remembered pilot links of a director: the
/// service refuses link writes from any other, live or queued, and the
/// participant a link names must still exist.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late PilotLinkFixture f;

  setUp(() async {
    harness = await AcceptorHarness.open(backend);
    f = PilotLinkFixture(harness);
    await f.setUp();
  });
  tearDown(() => harness.close());

  group('the installation that wrote the first link manages the links', () {
    setUp(() => f.managerLinks());

    test('keeps writing and correcting its links', () async {
      final edit = await f.send(harness.installationA, [
        harness.save(
          'PilotImportLink',
          f.link(f.linkA, f.p2, revision: 1),
          base: 0,
        ),
      ]);

      expect(edit.single.outcome, core.MutationOutcome.accepted);
      final stored = await harness.stored('PilotImportLink', f.linkA);
      expect(stored!['participant_profile_id'], f.p2.value);
    });

    test('another installation cannot add a link', () async {
      final result = await f.send(harness.installationB, [
        harness.save('PilotImportLink', f.link(f.linkB, f.p2, number: 13)),
      ]);

      expect(result.single.outcome, core.MutationOutcome.rejected);
      expect(result.single.reasonCode, 'not_link_manager');
      expect(await harness.stored('PilotImportLink', f.linkB), isNull);
    });

    test('another installation cannot correct or delete one', () async {
      final edit = await f.send(harness.installationB, [
        harness.save(
          'PilotImportLink',
          f.link(f.linkA, f.p3, revision: 1),
          base: 0,
        ),
      ]);
      final delete = await f.send(harness.installationB, [
        harness.delete('PilotImportLink', f.linkA, base: 0),
      ]);

      expect(edit.single.reasonCode, 'not_link_manager');
      expect(delete.single.reasonCode, 'not_link_manager');
      final stored = await harness.stored('PilotImportLink', f.linkA);
      expect(stored!['participant_profile_id'], f.p1.value);
    });

    test('queued edits sent after reconnecting are all refused', () async {
      final queue = [
        harness.save(
          'PilotImportLink',
          f.link(f.linkB, f.p2, number: 13),
          clientMutationId: 'b1',
        ),
        harness.save(
          'PilotImportLink',
          f.link(f.linkB, f.p3, number: 13, revision: 1),
          base: 0,
          clientMutationId: 'b2',
        ),
      ];

      final first = await f.send(harness.installationB, queue);
      final again = await f.send(harness.installationB, queue);

      for (final results in [first, again]) {
        expect(
          results.map((r) => r.reasonCode),
          everyElement('not_link_manager'),
        );
      }
      expect(await harness.stored('PilotImportLink', f.linkB), isNull);
      expect(await f.pending(), isEmpty);
    });
  });

  test('the first installation to write a link becomes the manager', () async {
    final b = await f.send(harness.installationB, [
      harness.save('PilotImportLink', f.link(f.linkB, f.p2)),
    ]);
    final a = await f.send(harness.installationA, [
      harness.save('PilotImportLink', f.link(f.linkA, f.p1, number: 13)),
    ]);

    expect(b.single.outcome, core.MutationOutcome.accepted);
    expect(a.single.reasonCode, 'not_link_manager');
  });

  group('a deleted participant', () {
    Future<void> deleteProfile(core.Id id) async {
      final out = await harness.exchange(
        f.scope,
        mutations: [
          harness.delete(
            'ParticipantProfile',
            id,
            base:
                (await harness.stored('ParticipantProfile', id))!['revision']
                    as int,
          ),
        ],
      );
      expect(out.results.single.outcome, core.MutationOutcome.accepted);
    }

    test('stays deleted when the manager links it offline', () async {
      await deleteProfile(f.p2);

      final result = await f.send(harness.installationA, [
        harness.save('PilotImportLink', f.link(f.linkA, f.p2)),
      ]);

      expect(result.single.reasonCode, 'entity_deleted');
      expect(await harness.stored('PilotImportLink', f.linkA), isNull);
      expect(await harness.stored('ParticipantProfile', f.p2), isNull);
    });

    test('takes its link with it, and a repeated delete is fine', () async {
      await f.managerLinks();

      await deleteProfile(f.p1);

      expect(await harness.stored('PilotImportLink', f.linkA), isNull);
      final again = await f.send(harness.installationA, [
        harness.delete('PilotImportLink', f.linkA, base: 0),
      ]);
      expect(again.single.outcome, core.MutationOutcome.accepted);
    });

    test('refuses a queued edit of a link that went with it', () async {
      await f.managerLinks();
      await deleteProfile(f.p1);

      final result = await f.send(harness.installationA, [
        harness.save(
          'PilotImportLink',
          f.link(f.linkA, f.p1, revision: 1),
          base: 0,
        ),
      ]);

      expect(result.single.outcome, core.MutationOutcome.rejected);
      expect(await harness.stored('PilotImportLink', f.linkA), isNull);
    });
  });
}
