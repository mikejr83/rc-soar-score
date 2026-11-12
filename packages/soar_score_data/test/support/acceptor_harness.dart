import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

import 'backends.dart';
import 'drawn_contest.dart';
import 'fixtures.dart';

/// The server's sync acceptor over a real database, and a client database
/// whose outbox supplies real mutations.
///
/// The server database uses the server profile on either backend. The client
/// is an in-memory SQLite installation, so what it writes into its outbox is
/// what a native installation would send.
class AcceptorHarness {
  AcceptorHarness._(this.server, this.client, this.serverRepository);

  static Future<AcceptorHarness> open(
    Backend backend, {
    int pageSize = 500,
    bool recalculates = false,
  }) async {
    // The client and the server are two databases on purpose.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final server = await Installation.open(
      backend,
      profile: DatabaseProfile.server,
    );
    await SystemDataSeeder(server.db).seed();
    final client = await Installation.open(Backend.sqlite);
    await SystemDataSeeder(client.db).seed();
    final harness = AcceptorHarness._(server, client, Repository(server.db));
    await harness.serverRepository.accountRepository.save(
      core.Account(
        id: harness.account,
        firstName: 'Dana',
        lastName: 'Pilot',
        email: 'dana@example.org',
        kind: core.AccountKind.registered,
        createdAt: DateTime.utc(2026, 10, 1),
        updatedAt: DateTime.utc(2026, 10, 1),
      ),
    );
    harness.service = SyncAcceptorService(
      harness.serverRepository,
      versions: const SyncVersions.exactly(1),
      pageSize: pageSize,
      recalculation: recalculates
          ? RecalculationService(ResultsService(harness.serverRepository))
          : null,
    );
    harness.installations = InstallationSyncService(harness.serverRepository);
    await harness.register(harness.installationA, 'Laptop');
    return harness;
  }

  final Installation server;
  final Installation client;
  final Repository serverRepository;
  late final SyncAcceptorService service;
  late final InstallationSyncService installations;

  /// The director who owns everything.
  final account = core.Id.create();
  final installationA = core.Id.create();
  final installationB = core.Id.create();

  late final Repository clientRepository = Repository(client.db);

  /// Another native installation, empty but for the system data.
  Future<Installation> openReceiver() async {
    final receiver = await Installation.open(Backend.sqlite);
    await SystemDataSeeder(receiver.db).seed();
    return receiver;
  }

  Future<void> close() async {
    await client.close();
    await server.close();
  }

  Future<core.Installation> register(core.Id id, String label) =>
      installations.register(
        accountId: account,
        id: id,
        label: label,
        platform: core.Platform.windows,
      );

  /// Builds a drawn F5J contest in the client's outbox.
  Future<core.Id> drawContestOnClient() =>
      drawnContest(clientRepository, account);

  /// The client's pending mutations of [scope] in an order the server can
  /// apply (parents before children).
  Future<List<SyncMutation>> outbox(core.SyncScopeKey scope) async {
    final pending = await client.syncStore.pendingMutations(scope);
    final indexed = [for (var i = 0; i < pending.length; i++) (i, pending[i])];
    indexed.sort((a, b) {
      final byType = _rank(a.$2.entityType).compareTo(_rank(b.$2.entityType));
      return byType != 0 ? byType : a.$1.compareTo(b.$1);
    });
    return [for (final (_, m) in indexed) toMutation(m)];
  }

  static SyncMutation toMutation(core.MutationRecord m) => SyncMutation(
    id: m.id,
    clientMutationId: m.clientMutationId,
    entityType: m.entityType,
    entityId: m.entityId,
    baseRevision: m.baseRevision,
    authority: m.authority,
    clientTime: m.clientTime,
    dependsOnMutationId: m.dependsOnMutationId,
    payload: m.payload,
  );

  static int _rank(String type) {
    const order = [
      'ParticipantProfile',
      'Role',
      'Contest',
      'ContestConfigurationRevision',
      'ContestParticipation',
      'Team',
      'TeamMembership',
      'MatrixRevision',
      'Round',
      'RoundGroup',
      'MatrixAssignment',
      'ScorePlaceholder',
      'ScoreAttempt',
      'OfficialScore',
    ];
    final i = order.indexOf(type);
    return i < 0 ? order.length : i;
  }

  /// Sends [mutations] for [scope] as [installation] (default A).
  Future<SyncExchangeOutput> exchange(
    core.SyncScopeKey scope, {
    List<SyncMutation> mutations = const [],
    core.Id? installation,
    int after = 0,
    String? pageToken,
    int? schemaVersion,
    int? protocolVersion,
    core.Id? as,
  }) => service.exchange(
    accountId: as ?? account,
    input: SyncExchangeInput(
      protocolVersion: protocolVersion ?? 1,
      schemaVersion: schemaVersion ?? 1,
      installationId: installation ?? installationA,
      scope: scope,
      lastAcknowledgedSequence: after,
      pageToken: pageToken,
      mutations: mutations,
    ),
  );

  /// Uploads the director's data, then the contest, from installation A, and
  /// records the answers on the client.
  Future<void> uploadAll(core.Id contestId) async {
    for (final scope in [
      core.DirectorScopeKey(account),
      core.ContestScopeKey(contestId),
    ]) {
      final sent = await outbox(scope);
      final out = await exchange(scope, mutations: sent);
      _requireAllAccepted(out);
      await acknowledge(sent, out.results);
    }
  }

  void _requireAllAccepted(SyncExchangeOutput out) {
    for (final r in out.results) {
      if (r.outcome != core.MutationOutcome.accepted) {
        throw StateError('not accepted: ${r.reasonCode} (${r.outcome})');
      }
    }
  }

  var _requests = 0;

  /// A save of [entity] as one mutation, based on [base].
  SyncMutation save(
    String type,
    Map<String, Object?> entity, {
    int? base,
    String? clientMutationId,
    core.Authority authority = core.Authority.director,
    String? supersedes,
  }) => SyncMutation(
    id: core.Id.create(),
    clientMutationId: clientMutationId ?? 'test-${_requests++}',
    entityType: type,
    entityId: core.Id.parse(entity['id']! as String),
    baseRevision: base,
    authority: authority,
    clientTime: DateTime.utc(2026, 10, 14),
    payload: MutationPayload.save(entity, supersedes: supersedes).toJson(),
  );

  /// A deletion of one entity as one mutation.
  SyncMutation delete(
    String type,
    core.Id id, {
    int? base,
    String? clientMutationId,
  }) => SyncMutation(
    id: core.Id.create(),
    clientMutationId: clientMutationId ?? 'test-${_requests++}',
    entityType: type,
    entityId: id,
    baseRevision: base,
    authority: core.Authority.director,
    clientTime: DateTime.utc(2026, 10, 14),
    payload: MutationPayload.delete.toJson(),
  );

  /// The entity as the server stores it.
  Future<Map<String, Object?>?> stored(String type, core.Id id) =>
      server.stores.of(type).findJson(id);

  /// Records the answers on the client, so [outbox] holds only what is new.
  Future<void> acknowledge(
    List<SyncMutation> sent,
    List<MutationResult> results,
  ) async {
    for (var i = 0; i < sent.length; i++) {
      await client.syncStore.recordOutcome(
        mutationId: sent[i].id,
        outcome: results[i].outcome,
        sequence: results[i].sequence,
        serverAcceptanceTime: DateTime.utc(2026, 10, 14),
        reasonCode: results[i].reasonCode,
      );
    }
  }

  /// The stored mutation records on the server.
  Future<int> serverMutationCount() => server.count('mutation_records');

  /// Applies pulled [changes] to the database of [target], as a client does.
  Future<void> applyChanges(
    Installation target,
    core.SyncScopeKey scope,
    List<AcceptedChange> changes,
  ) async {
    for (final c in changes) {
      await target.applier.apply(
        core.ReplicatedChange(
          scope: scope,
          sequence: c.sequence,
          entityType: c.entityType,
          entityId: c.entityId,
          revision: c.revision,
          payload: c.payload,
          isDelete: c.payload['deleted'] == true,
        ),
      );
    }
  }
}
