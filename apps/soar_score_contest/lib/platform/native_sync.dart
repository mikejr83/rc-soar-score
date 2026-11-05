import 'dart:async';
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_sync/soar_score_sync.dart';

import 'account_bound_sync_gateway.dart';
import 'acting_account.dart';
import 'engine_app_sync.dart';
import 'inspection_owner_guard.dart';
import 'installation_id_file.dart';

final _logger = Logger('NativeSync');

/// The sync engine of the native build, wired to the local database.
///
/// Local writes reach the scheduler through [SoarScoreDatabase.localChanges];
/// the remote API becoming reachable restarts every scope that was waiting.
/// Scopes of contests and data owned by the installation's Local account are
/// not synced: they have no account to sync to until sign-in claims them.
///
/// Contests the account owns on the service but this installation has never
/// held are found by listing the account's contests (see
/// [discoverAccountContests]); each is synced from the start of its stream.
/// Data of an account other than the one the app acts as is not synced.
///
/// Contests imported for inspection, and the director data that comes with
/// them, belong to an inspection owner (see [InspectionOwnerGuard]) and never
/// sync, whoever is signed in. That is decided explicitly, before any check
/// for an account, in every place that picks what to sync: [isSyncable],
/// the scheduler's local-change feed, [accountClaimed] and the gateway.
class NativeSync {
  NativeSync._(
    this.engine,
    this._scheduler,
    this._subscription,
    this._database,
    this._remote,
    this._discovered,
    this._discoveryDelay,
    this._acting,
    this._inspection,
    this._changes,
  ) : appSync = EngineAppSync(engine) {
    // Every ordinary sync, scheduled or started by the director, ends with a
    // look at the account's contests.
    var wasSyncing = false;
    _stateSubscription = engine.states.listen((state) {
      if (wasSyncing && !state.syncing) _discoverSoon();
      wasSyncing = state.syncing;
    });
    // Whoever started a sync, the next periodic check is one interval after
    // it, and a sync that found no connection says the service is unreachable.
    _outcomeSubscription = engine.outcomes.listen((failure) {
      _poller.synced();
      final reached = reachedService(failure);
      if (reached != null && !_reachability.isClosed) {
        _reachability.add(reached);
      }
    });
    _acting?.addListener(_accountChanged);
  }

  late final StreamSubscription<SyncState> _stateSubscription;
  late final StreamSubscription<SyncFailureKind?> _outcomeSubscription;
  late final SyncPoller _poller = SyncPoller(onPoll: _poll);
  final _entrySyncs = <core.SyncScopeKey>{};
  final _reachability = StreamController<bool>.broadcast();
  bool _reachable = false;
  SyncPollFocus _focus = const SyncPollLanding();

  /// What a sync that ended with [failure] says about the service: true when
  /// it got an answer (it completed, or the service refused it for a reason of
  /// its own such as an expired sign-in), false when there was no connection,
  /// and null for a server error (5xx), which says nothing either way: a
  /// gateway answering for a service that is down looks the same.
  static bool? reachedService(SyncFailureKind? failure) => switch (failure) {
    SyncFailureKind.offline => false,
    SyncFailureKind.serverError => null,
    _ => true,
  };

  /// What syncs find out about the service: true when one reached it, false
  /// when one found no connection.
  Stream<bool> get reachability => _reachability.stream;

  final ApiClient _remote;

  final ActingAccount? _acting;

  final InspectionOwnerGuard _inspection;

  /// Contests the service lists for an account that are not held locally
  /// yet, with that account; shared with the engine's `isSyncable` check.
  final Map<core.Id, core.Id> _discovered;
  core.Id? _accountId;
  Future<void>? _discovering;

  /// How long after a sync ends discovery waits, so the many scopes of a
  /// start-up or reconnect make one request.
  final Duration _discoveryDelay;
  Timer? _discoveryTimer;

  final SoarScoreDatabase _database;

  /// The engine.
  final SyncEngine engine;

  /// What the screens use; they never see the engine.
  final EngineAppSync appSync;
  final SyncScheduler _scheduler;
  final StreamSubscription<core.SyncScopeKey> _subscription;
  final _LocalChanges _changes;

  /// Builds the engine over [database], talking to [remote].
  static Future<NativeSync> start({
    required SoarScoreDatabase database,
    required core.Id localAccountId,
    required ApiClient remote,
    required String databasePath,
    Duration discoveryDelay = const Duration(seconds: 2),
    ActingAccount? acting,
    InspectionOwnerGuard? inspectionOwners,
  }) async {
    final inspection = inspectionOwners ?? InspectionOwnerGuard(database);
    final installationId = await InstallationIdFile.besides(databasePath)
        .readOrCreate();
    final contests = ContestRepository(database);
    final discovered = <core.Id, core.Id>{};
    // Who owns the data of a scope: the contest's owner, or for a contest
    // the service lists but this installation does not hold yet, the account
    // it was listed for.
    Future<core.Id?> ownerOf(core.SyncScopeKey scope) async => switch (scope) {
      core.ContestScopeKey(:final contestId) =>
        (await contests.findById(contestId))?.ownerAccountId ??
            discovered[contestId],
      core.DirectorScopeKey(:final ownerAccountId) => ownerAccountId,
      core.SystemScopeKey() => null,
    };
    Future<bool> isSyncable(core.SyncScopeKey scope) async {
      if (scope is core.SystemScopeKey) return true;
      final owner = await ownerOf(scope);
      // No owner, or the Local account, has no account to sync to.
      if (owner == null || owner == localAccountId) return false;
      try {
        // Before the account check: with no acting account that check lets
        // any other owner through.
        if (await inspection.isInspection(owner)) return false;
      } on Object catch (error, stack) {
        // Unreadable markers: only an owner a sign-in is acting for may sync.
        _logger.warning('Could not read the inspection owners', error, stack);
        return acting != null && acting.leaseFor(owner) != null;
      }
      return _hasAccount(owner, localAccountId, acting);
    }

    /// Whether a local change in [scope] may be handed to the scheduler.
    /// Fails closed: a scope whose owner cannot be told is not queued.
    Future<bool> mayQueue(core.SyncScopeKey scope) async {
      try {
        return !await inspection.isInspection(await ownerOf(scope));
      } on Object {
        return false;
      }
    }

    final api = ApiClientSyncGateway(remote);
    final engine = SyncEngine(
      store: DriftSyncStore(database),
      applier: DriftReplicatedChangeApplier(
        database,
        EntityStores.forDatabase(database),
      ),
      gateway: acting == null
          ? InspectionGuardedSyncGateway(
              api,
              ownerOf: ownerOf,
              isInspectionOwner: inspection.isInspection,
            )
          : AccountBoundSyncGateway(
              api,
              acting: acting,
              ownerOf: ownerOf,
              isInspectionOwner: inspection.isInspection,
            ),
      config: SyncEngineConfig(
        installationId: installationId,
        label: io.Platform.localHostname,
        platform: io.Platform.isWindows
            ? core.Platform.windows
            : core.Platform.other,
        schemaVersion: database.schemaVersion,
        isSyncable: isSyncable,
      ),
    );
    final scheduler = SyncScheduler(engine);
    // Each look at a local change reads the database (who owns the scope),
    // so close() must wait for the ones still running.
    final changes = _LocalChanges();
    final subscription = database.localChanges.listen((scope) {
      changes.run(() async {
        if (await mayQueue(scope)) scheduler.notifyLocalChange(scope);
      });
    });
    _logger.info('Sync engine ready for installation $installationId');
    return NativeSync._(
      engine,
      scheduler,
      subscription,
      database,
      remote,
      discovered,
      discoveryDelay,
      acting,
      inspection,
      changes,
    );
  }

  /// Whether [owner] is an account to sync for. With [acting] only the
  /// account the app acts as, under its current sign-in, qualifies: data of
  /// another account (claimed before the director signed in as someone else)
  /// must not be sent with this sign-in's credentials, and nothing syncs
  /// while the app acts as the Local account.
  static bool _hasAccount(
    core.Id? owner,
    core.Id localAccountId,
    ActingAccount? acting,
  ) {
    if (owner == null || owner == localAccountId) return false;
    return acting == null || acting.leaseFor(owner) != null;
  }

  /// The remote API became reachable (or stopped being so).
  void remoteReachabilityChanged({required bool reachable}) {
    _reachable = reachable;
    _updatePoller();
    if (!reachable) return;
    _scheduler.connectivityRestored();
    unawaited(discoverAccountContests());
  }

  /// The account a periodic check may sync for: the claimed one, while the app
  /// still acts as it. Null before a sign-in claimed the Local account and
  /// after the director signed out.
  core.Id? get _syncAccount {
    final account = _accountId;
    if (account == null) return null;
    final acting = _acting;
    return acting == null || acting.leaseFor(account) != null ? account : null;
  }

  void _accountChanged() => _updatePoller();

  /// Checks run only while the service is reachable and an account is signed
  /// in; the screens show the account's sync status while there is one.
  void _updatePoller() {
    final account = _syncAccount;
    _poller.enabled = _reachable && account != null;
    appSync.accountScopeChanged(
      account == null ? null : core.DirectorScopeKey(account),
    );
  }

  /// The director moved to a contest's pages ([contestId]) or out of them.
  /// Opening a contest not synced for a while syncs it at once.
  void focusChanged(String? contestId) {
    core.Id? id;
    if (contestId != null) {
      try {
        id = core.Id.parse(contestId);
      } on ArgumentError {
        // A location that is not a contest: treat it as outside one.
      }
    }
    _focus = id == null ? const SyncPollLanding() : SyncPollContest(id);
    _poller.focusChanged(_focus);
    if (id == null || !_reachable || _syncAccount == null) return;
    final scope = core.ContestScopeKey(id);
    final last = engine.state.scopes[scope]?.lastSyncedAt;
    final stale =
        last == null ||
        DateTime.now().difference(last) >= _poller.contestInterval;
    // Moving quickly between pages must not queue the same sync again.
    if (!stale || !_entrySyncs.add(scope)) return;
    unawaited(
      engine
          .syncScope(scope)
          .catchError((Object error, StackTrace stack) {
            _logger.warning(
              'Could not sync on opening a contest',
              error,
              stack,
            );
            return null;
          })
          .whenComplete(() => _entrySyncs.remove(scope)),
    );
  }

  /// The app went to the background or came back to the front.
  void appActiveChanged({required bool active}) => _poller.paused = !active;

  /// One periodic check: the contest in front, the director's data, and a
  /// look for contests made on another installation.
  Future<void> _poll(SyncPollFocus focus) async {
    final account = _syncAccount;
    // The engine runs syncs one after another, so a sync of another scope
    // under way only delays this check.
    if (account == null) return;
    final steps = <Future<Object?> Function()>[
      if (focus case SyncPollContest(:final contestId))
        () => engine.syncScope(core.ContestScopeKey(contestId)),
      () => engine.syncScope(core.DirectorScopeKey(account)),
      discoverAccountContests,
    ];
    // One step failing must not skip the others.
    for (final step in steps) {
      try {
        await step();
      } on Object catch (error, stack) {
        _logger.warning('A periodic sync check step failed', error, stack);
      }
    }
  }

  /// The Local account's data now belongs to [accountId]: sync every scope it
  /// made syncable (the director's own data, the system data and the account's
  /// contests), which were skipped while they were local only.
  Future<void> accountClaimed(core.Id accountId) async {
    _accountId = accountId;
    _updatePoller();
    final scopes = <core.SyncScopeKey>[core.DirectorScopeKey(accountId)];
    try {
      for (final contest in await ContestRepository(_database).getAll()) {
        if (contest.ownerAccountId == accountId &&
            !await _inspection.isInspection(contest.ownerAccountId)) {
          scopes.add(core.ContestScopeKey(contest.id));
        }
      }
    } on Object catch (error, stack) {
      // The scheduler knows these scopes from now on, so the contests follow
      // with the next local change or when the service is reachable again.
      _logger.warning('Could not list the claimed contests', error, stack);
    } finally {
      scopes.forEach(_scheduler.notifyLocalChange);
      // The system data has its own stream; the scheduler cannot sync it.
      unawaited(engine.syncSystemData());
    }
    await discoverAccountContests();
  }

  /// Looks once, [_discoveryDelay] after the last call: every sync that ends
  /// within that time shares one request.
  void _discoverSoon() {
    if (_accountId == null || _discoveryTimer != null) return;
    _discoveryTimer = Timer(_discoveryDelay, () {
      _discoveryTimer = null;
      unawaited(discoverAccountContests());
    });
  }

  /// Lists the signed-in account's contests on the service and starts syncing
  /// the ones this installation does not hold, such as a contest made offline
  /// on the director's other installation.
  ///
  /// Does nothing before the account is known (no sign-in claimed yet). A
  /// failure is logged; the next claim or the service becoming reachable
  /// again tries once more. It also runs after syncs, at most once per
  /// burst. Calls overlapping a running one share it.
  Future<void> discoverAccountContests() {
    if (_accountId == null) return Future.value();
    return _discovering ??= _discover(_accountId!)
        .whenComplete(() => _discovering = null);
  }

  Future<void> _discover(core.Id accountId) async {
    try {
      final held = {
        for (final contest in await ContestRepository(_database).getAll())
          contest.id,
      };
      // The listing carries the account's token: bound to its sign-in, and
      // only used while that account still is the acting one.
      final acting = _acting;
      final lease = acting?.leaseFor(accountId);
      if (acting != null && lease == null) return;
      final listed = acting == null
          ? await _remote.contests()
          : await acting.epoch.runBound(lease!, _remote.contests);
      if (acting != null && acting.leaseFor(accountId) != lease) return;
      for (final contest in listed) {
        if (contest.ownerAccountId != accountId || held.contains(contest.id)) {
          continue;
        }
        // A contest found before is already known to the scheduler, which
        // retries it; only a new one starts a sync, so this cannot loop.
        final isNew = !_discovered.containsKey(contest.id);
        _discovered[contest.id] = accountId;
        if (isNew) {
          _scheduler.notifyLocalChange(core.ContestScopeKey(contest.id));
        }
      }
    } on Object catch (error, stack) {
      _logger.fine('Could not list the account contests', error, stack);
    }
  }

  Future<void> close() async {
    // Nothing new starts, and what already started finishes while the
    // database is still open.
    _changes.closing = true;
    await _subscription.cancel();
    await _changes.idle();
    await _stateSubscription.cancel();
    await _outcomeSubscription.cancel();
    _acting?.removeListener(_accountChanged);
    _poller.dispose();
    await _reachability.close();
    _discoveryTimer?.cancel();
    _scheduler.dispose();
    // A sync in flight finishes before the database closes under it.
    await engine.dispose();
    await appSync.close();
    // A look at the account's contests may still be reading the database,
    // which answers from its own isolate: let it finish before the database
    // closes under it.
    try {
      await _discovering;
    } on Object {
      // Logged where it happened.
    }
  }
}

/// The look at each local change that is still running, so closing can wait
/// for them instead of leaving them to read a closed database.
class _LocalChanges {
  final _running = <Future<void>>{};

  /// Set once the sync is closing: later changes are not looked at.
  bool closing = false;

  void run(Future<void> Function() work) {
    if (closing) return;
    late final Future<void> done;
    done = work()
        .catchError((Object error, StackTrace stack) {
          _logger.warning('A local change was not queued', error, stack);
        })
        .whenComplete(() => _running.remove(done));
    _running.add(done);
  }

  Future<void> idle() async {
    while (_running.isNotEmpty) {
      await Future.wait(_running.toList());
    }
  }
}
