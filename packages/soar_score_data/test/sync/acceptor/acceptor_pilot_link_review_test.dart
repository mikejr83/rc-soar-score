import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';
import 'acceptor_pilot_link_support.dart';

void main() => forEachBackend(_tests);

/// The director's way out of a disagreement about a pilot link that already
/// exists: keep the saved link, use the other device's, or pick another
/// participant. A decision is about the comparison that was shown.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late PilotLinkFixture f;
  late core.ConflictRecord review;

  setUp(() async {
    harness = await AcceptorHarness.open(backend);
    f = PilotLinkFixture(harness);
    await f.setUp();
    await f.managerLinks();
    review = await f.existingDisagreement(offered: f.p2);
  });
  tearDown(() => harness.close());

  Future<String?> participantOf(core.Id link) async =>
      (await harness.stored('PilotImportLink', link))?['participant_profile_id']
          as String?;

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

  test('keeping the saved link leaves it as it is', () async {
    final result = await f.resolve(
      review.id,
      core.ConflictResolutionChoice.keptAccepted,
    );

    expect(result.outcome, core.MutationOutcome.accepted);
    expect(await participantOf(f.linkA), f.p1.value);
    expect(await f.pending(), isEmpty);
  });

  test('using the other link makes it the saved one', () async {
    final result = await f.resolve(
      review.id,
      core.ConflictResolutionChoice.tookCompeting,
    );

    expect(result.outcome, core.MutationOutcome.accepted);
    expect(await participantOf(f.linkA), f.p2.value);
    expect((await harness.stored('PilotImportLink', f.linkA))!['revision'], 1);
    final pulled = await harness.exchange(f.scope, after: 0);
    final change = pulled.changes.lastWhere(
      (c) => c.entityType == 'PilotImportLink',
    );
    expect(change.payload['participant_profile_id'], f.p2.value);
  });

  test('another participant can be chosen', () async {
    final result = await f.resolve(
      review.id,
      core.ConflictResolutionChoice.merged,
      payload: {'participant_profile_id': f.p3.value},
    );

    expect(result.outcome, core.MutationOutcome.accepted);
    expect(await participantOf(f.linkA), f.p3.value);
    expect(await f.pending(), isEmpty);
  });

  test('a participant deleted before the choice is saved is refused', () async {
    await deleteProfile(f.p3);

    final result = await f.resolve(
      review.id,
      core.ConflictResolutionChoice.merged,
      payload: {'participant_profile_id': f.p3.value},
    );

    expect(result.outcome, core.MutationOutcome.rejected);
    expect(result.reasonCode, 'entity_deleted');
    expect(await participantOf(f.linkA), f.p1.value);
    expect(await f.pending(), hasLength(1));
  });

  test('a choice that names no participant is refused', () async {
    final result = await f.resolve(
      review.id,
      core.ConflictResolutionChoice.merged,
      payload: const {},
    );

    expect(result.reasonCode, 'invalid_payload');
  });

  test('the same decision sent twice is applied once', () async {
    await f.resolve(review.id, core.ConflictResolutionChoice.tookCompeting);
    final again = await f.resolve(
      review.id,
      core.ConflictResolutionChoice.tookCompeting,
    );

    expect(again.outcome, core.MutationOutcome.accepted);
    expect((await harness.stored('PilotImportLink', f.linkA))!['revision'], 1);
  });

  test('a change to the saved link replaces the review', () async {
    await f.send(harness.installationA, [
      harness.save(
        'PilotImportLink',
        f.link(f.linkA, f.p1, revision: 1, values: {'club': 'south'}),
        base: 0,
      ),
    ]);

    final open = (await f.pending()).single;
    expect(open.id, isNot(review.id));
    expect(open.entityRevision, 1);
    final stale = await f.resolve(
      review.id,
      core.ConflictResolutionChoice.tookCompeting,
    );
    expect(stale.reasonCode, 'stale_base');
    expect(await participantOf(f.linkA), f.p1.value);
    final fresh = await f.resolve(
      open.id,
      core.ConflictResolutionChoice.tookCompeting,
      id: 'decide-2',
    );
    expect(fresh.outcome, core.MutationOutcome.accepted);
  });

  test('a participant deleted while it waits closes the review', () async {
    await deleteProfile(f.p2);

    expect(await f.pending(), isEmpty);
    expect(await participantOf(f.linkA), f.p1.value);
  });

  test('the other links are reviewed after the saved one goes', () async {
    final linkC = core.Id.create();
    await f.existingDisagreement(offered: f.p3, offeredLink: linkC);

    await f.send(harness.installationA, [
      harness.delete('PilotImportLink', f.linkA, base: 0),
    ]);

    final waiting = await f.pending();
    expect(waiting, hasLength(1));
    expect(waiting.single.entityId, f.linkB);
    expect(
      waiting.single.acceptedPayload!['participant_profile_id'],
      f.p2.value,
    );
    expect(
      waiting.single.competingPayload!['participant_profile_id'],
      f.p3.value,
    );
    expect(await harness.stored('PilotImportLink', linkC), isNull);
  });
}
