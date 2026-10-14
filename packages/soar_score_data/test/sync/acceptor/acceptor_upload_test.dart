import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';

void main() => forEachBackend(_tests);

/// An installation uploads a contest it built offline, and another
/// installation of the same account receives it.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late core.Id contestId;

  setUp(() async {
    harness = await AcceptorHarness.open(backend);
    contestId = await harness.drawContestOnClient();
  });
  tearDown(() => harness.close());

  test('the first upload of a contest is accepted and activates it', () async {
    final scope = core.ContestScopeKey(contestId);
    await harness.exchange(
      core.DirectorScopeKey(harness.account),
      mutations: await harness.outbox(core.DirectorScopeKey(harness.account)),
    );
    final mutations = await harness.outbox(scope);

    final out = await harness.exchange(scope, mutations: mutations);

    expect(out.results, hasLength(mutations.length));
    expect(
      out.results.map((r) => r.outcome),
      everyElement(core.MutationOutcome.accepted),
    );
    final sequences = [for (final r in out.results) r.sequence!];
    expect(
      sequences,
      unorderedEquals([for (var i = 1; i <= sequences.length; i++) i]),
    );
    expect(out.serverSequence, sequences.length);
    final activations = await harness
        .serverRepository
        .installationActivationRepository
        .listForContest(contestId);
    expect(activations, hasLength(1));
    expect(activations.single.installationId, harness.installationA);
    expect(activations.single.kind, core.ActivationKind.initial);
    expect(activations.single.isOpen, isTrue);
    expect(
      await harness.serverRepository.contestRepository.findById(contestId),
      isNotNull,
    );
  });

  test('another installation receives the contest and applies it', () async {
    await harness.uploadAll(contestId);
    await harness.register(harness.installationB, 'Tablet');
    final scope = core.ContestScopeKey(contestId);

    final pulled = await harness.exchange(
      scope,
      installation: harness.installationB,
    );

    expect(pulled.results, isEmpty);
    expect(pulled.changes, isNotEmpty);
    expect([
      for (final c in pulled.changes) c.sequence,
    ], orderedEquals([for (var i = 1; i <= pulled.changes.length; i++) i]));
    final receiver = harness.client;
    // The director's data first, as a client pulls it.
    final people = await harness.exchange(
      core.DirectorScopeKey(harness.account),
      installation: harness.installationB,
    );
    final other = await harness.openReceiver();
    await harness.applyChanges(
      other,
      core.DirectorScopeKey(harness.account),
      people.changes,
    );
    await harness.applyChanges(other, scope, pulled.changes);
    final stored = await other.stores.of('Contest').findJson(contestId);
    final original = await receiver.stores.of('Contest').findJson(contestId);
    expect(stored, original);
    for (final type in ['MatrixAssignment', 'ScorePlaceholder', 'Round']) {
      expect(
        (await other.stores.of(type).all()),
        hasLength((await receiver.stores.of(type).all()).length),
        reason: type,
      );
    }
    await other.close();
  });

  test(
    'repeating a request returns the same answers and adds nothing',
    () async {
      final scope = core.ContestScopeKey(contestId);
      await harness.exchange(
        core.DirectorScopeKey(harness.account),
        mutations: await harness.outbox(core.DirectorScopeKey(harness.account)),
      );
      final mutations = await harness.outbox(scope);
      final first = await harness.exchange(scope, mutations: mutations);
      final stored = await harness.serverMutationCount();

      final again = await harness.exchange(scope, mutations: mutations);

      expect(again.results, first.results);
      expect(await harness.serverMutationCount(), stored);
      expect(again.serverSequence, first.serverSequence);
    },
  );

  test('a rejected mutation does not stop its siblings', () async {
    await harness.exchange(
      core.DirectorScopeKey(harness.account),
      mutations: await harness.outbox(core.DirectorScopeKey(harness.account)),
    );
    final scope = core.ContestScopeKey(contestId);
    final mutations = await harness.outbox(scope);
    final derived = SyncMutation(
      id: core.Id.create(),
      clientMutationId: 'derived-1',
      entityType: 'FlightResult',
      entityId: core.Id.create(),
      authority: core.Authority.director,
      clientTime: DateTime.utc(2026, 10, 14),
      payload: MutationPayload.save({'id': 'x'}).toJson(),
    );
    final dependent = SyncMutation(
      id: core.Id.create(),
      clientMutationId: 'dependent-1',
      entityType: 'Round',
      entityId: core.Id.create(),
      authority: core.Authority.director,
      clientTime: DateTime.utc(2026, 10, 14),
      dependsOnMutationId: derived.id,
      payload: MutationPayload.save({'id': 'y'}).toJson(),
    );

    final out = await harness.exchange(
      scope,
      mutations: [derived, ...mutations, dependent],
    );

    expect(out.results.first.outcome, core.MutationOutcome.rejected);
    expect(out.results.first.reasonCode, 'invalid_payload');
    expect(out.results.last.outcome, core.MutationOutcome.skipped);
    expect(out.results.last.reasonCode, 'dependency_failed');
    expect(out.results.last.dependsOn, 'derived-1');
    expect(
      out.results.sublist(1, out.results.length - 1).map((r) => r.outcome),
      everyElement(core.MutationOutcome.accepted),
    );
  });

  test('the pull is paged and resumes from the token', () async {
    await harness.close();
    harness = await AcceptorHarness.open(backend, pageSize: 5);
    contestId = await harness.drawContestOnClient();
    await harness.uploadAll(contestId);
    final scope = core.ContestScopeKey(contestId);

    final first = await harness.exchange(scope);
    expect(first.changes, hasLength(5));
    expect(first.nextPageToken, isNotNull);
    final all = [...first.changes];
    var token = first.nextPageToken;
    while (token != null) {
      final page = await harness.exchange(scope, pageToken: token);
      all.addAll(page.changes);
      token = page.nextPageToken;
    }

    expect(all.length, first.serverSequence);
    expect([
      for (final c in all) c.sequence,
    ], orderedEquals([for (var i = 1; i <= all.length; i++) i]));
  });

  test('a page token for another scope has expired', () async {
    await harness.close();
    harness = await AcceptorHarness.open(backend, pageSize: 5);
    contestId = await harness.drawContestOnClient();
    await harness.uploadAll(contestId);
    final first = await harness.exchange(core.ContestScopeKey(contestId));

    expect(
      () => harness.exchange(
        core.DirectorScopeKey(harness.account),
        pageToken: first.nextPageToken,
      ),
      throwsA(
        isA<core.SyncRefusal>().having((e) => e.statusCode, 'status', 410),
      ),
    );
    expect(
      () => harness.exchange(
        core.ContestScopeKey(contestId),
        pageToken: 'garbage',
      ),
      throwsA(isA<core.SyncRefusal>()),
    );
  });
}
