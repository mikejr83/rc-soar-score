import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';

/// The shared setup of the pilot link acceptor tests: a director with three
/// participants and helpers to send link edits from either installation.
class PilotLinkFixture {
  PilotLinkFixture(this.harness);

  final AcceptorHarness harness;
  late core.DirectorScopeKey scope;
  late core.Id p1, p2, p3, linkA, linkB;
  static const pilot = 12;

  Future<core.Id> addProfile(String name) async {
    final now = DateTime.utc(2026, 10);
    final profile = core.ParticipantProfile(
      id: core.Id.create(),
      ownerAccountId: harness.account,
      firstName: name,
      lastName: 'Pilot',
      createdAt: now,
      updatedAt: now,
    );
    final out = await harness.exchange(
      scope,
      mutations: [harness.save('ParticipantProfile', profile.toJson())],
    );
    expect(out.results.single.outcome, core.MutationOutcome.accepted);
    return profile.id;
  }

  Future<void> setUp() async {
    await harness.register(harness.installationB, 'Tablet');
    scope = core.DirectorScopeKey(harness.account);
    p1 = await addProfile('Ada');
    p2 = await addProfile('Grace');
    p3 = await addProfile('Edith');
    linkA = core.Id.create();
    linkB = core.Id.create();
  }

  Map<String, Object?> link(
    core.Id id,
    core.Id profile, {
    int revision = 0,
    int number = pilot,
    Map<String, Object?> values = const {},
  }) => core.PilotImportLink(
    id: id,
    ownerAccountId: harness.account,
    sourcePilotNo: number,
    participantProfileId: profile,
    sourceValues: values,
    createdAt: DateTime.utc(2026, 10),
    updatedAt: DateTime.utc(2026, 10, 1, revision),
    revision: revision,
  ).toJson();

  Future<List<core.MutationResult>> send(
    core.Id installation,
    List<core.SyncMutation> mutations,
  ) async => (await harness.exchange(
    scope,
    installation: installation,
    mutations: mutations,
  )).results;

  Future<List<core.ConflictRecord>> pending() => harness
      .serverRepository
      .syncAcceptorStore
      .transaction((tx) => tx.conflictsNeedingAction(scope));

  Future<core.MutationResult> resolve(
    core.Id conflictId,
    core.ConflictResolutionChoice choice, {
    String id = 'decide',
    Map<String, Object?>? payload,
  }) => harness.service.resolveConflict(
    accountId: harness.account,
    conflictId: conflictId,
    clientMutationId: id,
    choice: choice,
    payload: payload,
  );

  /// Installation A writes the link for the pilot: A manages the links.
  Future<void> managerLinks({core.Id? profile}) async {
    final a = await send(harness.installationA, [
      harness.save('PilotImportLink', link(linkA, profile ?? p1)),
    ]);
    expect(a.single.outcome, core.MutationOutcome.accepted);
  }

  /// A disagreement as the service recorded it before links had a single
  /// manager: the stored link, and a link another device offered for the
  /// same pilot.
  Future<core.ConflictRecord> existingDisagreement({
    required core.Id offered,
    core.Id? offeredLink,
  }) async {
    final stored = (await harness.stored('PilotImportLink', linkA))!;
    final record = core.ConflictRecord(
      id: core.Id.create(),
      ownerAccountId: harness.account,
      entityType: 'PilotImportLink',
      entityId: linkA,
      competingMutationId: core.Id.create(),
      reasonCode: 'unique_violation',
      createdAt: DateTime.utc(2026, 10, 2),
      acceptedPayload: stored,
      competingPayload: link(offeredLink ?? linkB, offered),
      entityRevision: stored['revision'] as int?,
    );
    await harness.serverRepository.syncAcceptorStore.transaction(
      (tx) => tx.saveConflict(record),
    );
    return record;
  }
}
