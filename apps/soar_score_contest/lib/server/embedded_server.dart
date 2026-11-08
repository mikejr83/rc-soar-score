import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' show Pipeline;
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

import '../platform/inspection_owner_guard.dart';
import 'embedded_guard.dart';
import 'owner_scoped_principal.dart';
import 'profile_access.dart';
import 'profile_mismatch_guard.dart';

final _logger = Logger('EmbeddedServer');

const String embeddedServerName = 'soar_score_contest';
const String embeddedServerDisplayName = 'Soar Score Contest (Offline)';
const String embeddedServerVersion = '0.1.0';

/// An in-process instance of the Soar Score API served by the Windows build
/// of `soar_score_contest` (ticket 018).
///
/// Bound to the IPv4 loopback address on an OS-assigned free port so
/// concurrent instances can never conflict; [baseUrl] is the loopback address
/// the app's own `ApiClient` (from `soar_score_api`) is pointed at. Every
/// request but `GET /health` must carry [secret] as a bearer token (see
/// `embeddedGuard`).
class EmbeddedServer {
  EmbeddedServer._(
    this._databasePath, {
    required this.seedDemo,
    this.drawRunner,
  });

  final String _databasePath;

  /// Whether to fill an empty database with the demo data.
  final bool seedDemo;

  /// Where matrix draws run; null is the API's default, an isolate of their
  /// own.
  final core.DrawRunner? drawRunner;
  late HttpServer _server;

  /// The per-launch bearer secret, held in memory only. The app's own client
  /// gets it through its `tokenProvider`.
  final String secret = generateEmbeddedSecret();
  late SoarScoreDatabase _database;
  late core.Repository _repository;
  late core.Id _localAccountId;
  late core.Id _actingAccountId;
  core.Id? _linkedAccountId;
  String? _linkedSubject;
  bool _signedIn = false;
  String? _signedSubject;
  ProfileAccess _profileAccess = ProfileAccess.verified;

  /// Which owner ids belong to contests imported for inspection. Shared with
  /// the sync engine, so both decide from the same answers.
  late final InspectionOwnerGuard inspectionOwners = InspectionOwnerGuard(
    _database,
  );

  /// The OS-assigned port the local socket is bound to.
  int get port => _server.port;

  /// The loopback base URL the app's `ApiClient` should target.
  Uri get baseUrl => Uri.parse('http://127.0.0.1:$port');

  core.Repository get repository => _repository;

  /// The local database, for the sync engine's store and applier.
  SoarScoreDatabase get database => _database;

  /// The installation's Local account, which owns the contests created here.
  core.Id get localAccountId => _localAccountId;

  /// The account every request acts as: the owner of what it creates and the
  /// actor of its mutations. The Local account until [actAs] says otherwise.
  core.Id get actingAccountId => _actingAccountId;

  /// Acts as the signed-in [accountId] from now on, so new contests and
  /// roles belong to it from the start and sync at once.
  void actAs(core.Id accountId) {
    _actingAccountId = accountId;
    _linkedAccountId = accountId;
    _profileAccess = ProfileAccess.verified;
  }

  /// Whether the claimed account's data may be served now.
  ProfileAccess get profileAccess => _profileAccess;

  /// Whether the service refused the signed-in account's claim.
  bool get profileMismatch => _profileAccess == ProfileAccess.mismatched;

  /// Throws [ProfileUnavailableError] unless the claimed account's data may be
  /// served. Every path that reads or writes it without going through the
  /// HTTP API calls this first.
  void assertProfileUsable() {
    if (_profileAccess != ProfileAccess.verified) {
      throw ProfileUnavailableError(_profileAccess);
    }
  }

  /// A user signed in (or was restored) with identity [subject]. The claimed
  /// data is served only when [subject] is the one that claimed it; otherwise
  /// it stays closed until the claim is checked, or the user signs out.
  void profileSignedIn(String? subject) {
    _signedIn = true;
    _signedSubject = subject;
    _profileAccess = _accessForSignedIn();
  }

  ProfileAccess _accessForSignedIn() =>
      _linkedAccountId == null ||
          (_signedSubject != null && _signedSubject == _linkedSubject)
      ? ProfileAccess.verified
      : ProfileAccess.unverified;

  /// A claim by [subject] committed: this installation's data now belongs to
  /// [accountId]. Synchronous, and called right after the data was re-pointed
  /// whatever the sign-in has done since, so memory never lags the database.
  ///
  /// The server then acts as the account, as it does after sign-out, so no
  /// request ever acts as the Local account over rows the account owns. That
  /// grants no sync lease: sending still waits for [actAs] under a sign-in
  /// that is still current. Who may see the data is decided here as at any
  /// sign-in: a user other than the claimant is closed out (`mismatched`
  /// stays so) until their own claim is checked.
  void recordClaim(core.Id accountId, String? subject) {
    _linkedAccountId = accountId;
    _linkedSubject = subject;
    _actingAccountId = accountId;
    _profileAccess = !_signedIn
        ? ProfileAccess.verified
        : _profileAccess == ProfileAccess.mismatched
        ? ProfileAccess.mismatched
        : _accessForSignedIn();
  }

  /// The service refused the signed-in account's claim because the data is
  /// another account's: stop serving that data until the director signs out or
  /// signs in as the owning account.
  void markProfileMismatch() => _profileAccess = ProfileAccess.mismatched;

  /// Signed out: acts as the account the data was last claimed into, so the
  /// director still sees it, or as the Local account if it was never claimed.
  void actAsLocal() {
    _signedIn = false;
    _signedSubject = null;
    _actingAccountId = _linkedAccountId ?? _localAccountId;
    _profileAccess = ProfileAccess.verified;
  }

  Future<void> initializeDatabase() async {
    final dbPath = File(_databasePath);
    _logger.finer('Using database path: ${dbPath.path}');
    await dbPath.parent.create(recursive: true);
    _database = createLocalDatabase(dbPath);
    // First launch installs the shipped system data so a director who has
    // never synchronized can create and score contests offline. A failure
    // closes the database and reaches the startup failure page, so the app
    // never starts with partial data.
    try {
      await SystemDataSeeder(_database).seed();
      _localAccountId = await LocalAccountRepository(_database).ensure();
      // A claimed installation owns its data as the account, so it starts as
      // that account even offline; the sign-in only decides what is synced.
      _linkedAccountId = await LocalAccountRepository(_database)
          .linkedAccount();
      _linkedSubject = await LocalAccountRepository(_database).linkedSubject();
      _actingAccountId = _linkedAccountId ?? _localAccountId;
      // A claimed profile stays closed until the app has compared the
      // restored sign-in (or its absence) with the claim: see
      // [profileSignedIn] and [actAsLocal].
      _profileAccess = _linkedAccountId == null
          ? ProfileAccess.verified
          : ProfileAccess.unverified;
      if (seedDemo) {
        _logger.finer('Seeding demo data');
        await DemoDataSeeder(
          Repository(_database),
          localAccountId: _localAccountId,
        ).seed();
      }
    } catch (_) {
      await _database.close();
      rethrow;
    }
  }

  Future<void> initialize() async {
    _repository = Repository(_database);

    final handler = buildApiHandler(
      name: embeddedServerName,
      displayName: embeddedServerDisplayName,
      version: embeddedServerVersion,
      schemaRevision: _database.schemaVersion,
      repository: _repository,
      authMiddleware: ownerScopedPrincipal(
        acting: () => _actingAccountId,
        database: _database,
        guard: inspectionOwners,
      ),
      gliderScoreImport: GliderScoreImportProcessRunner(),
      drawRunner: drawRunner,
    );
    final guarded = Pipeline()
        .addMiddleware(_inFlight.middleware)
        .addMiddleware(embeddedGuard(secret: secret, port: () => port))
        .addMiddleware(profileMismatchGuard(access: () => _profileAccess))
        .addHandler(handler);
    _server = await shelf_io.serve(guarded, InternetAddress.loopbackIPv4, 0);
  }

  final _inFlight = InFlightRequests();

  /// Shuts down the HTTP server and closes the local database, releasing the
  /// port and the SQLite file handle.
  ///
  /// New requests are refused and the running ones finish before the
  /// database closes under them. Connections still open after
  /// [drainTimeout] (an abnormal shutdown) are then closed by force.
  Future<void> close({
    Duration drainTimeout = const Duration(seconds: 10),
  }) async {
    final graceful = _server.close();
    if (!await _inFlight.drain(timeout: drainTimeout)) {
      _logger.warning('Closing with ${_inFlight.count} requests still running');
    }
    // The handlers are done; the connections finish writing their answers.
    try {
      await graceful.timeout(drainTimeout);
    } on TimeoutException {
      await _server.close(force: true);
    }
    await _database.close();
  }
}

/// Opens the local SQLite database at [databasePath] (parent directories are
/// created if needed) and starts the embedded API on `127.0.0.1` with an
/// OS-assigned free port (port `0` is passed to `shelf_io.serve`).
///
/// The embedded instance has no sign-in (ticket 017) but requires the
/// per-launch [EmbeddedServer.secret] on every request but `GET /health`,
/// and refuses foreign `Host` and any `Origin` (#425, `docs/embedded-api-security.md`).
/// Every request that passes acts as an account chosen by the app, through the
/// same `Principal` seam the hosted server fills from a verified token: the installation's
/// Local account, or the signed-in account once the Local account is claimed
/// (see [EmbeddedServer.actAs]).
///
/// With [seedDemo], an empty database gets the example data of
/// `DemoDataSeeder` (development only; the app passes it for the demo
/// database).
///
/// [drawRunner] replaces where matrix draws run (the E2E builds slow them
/// down so a journey can cancel one); by default each draw runs on an isolate
/// of its own, so a long draw never freezes the app.
Future<EmbeddedServer> startEmbeddedServer(
  String databasePath, {
  bool seedDemo = false,
  core.DrawRunner? drawRunner,
}) async {
  final server = EmbeddedServer._(
    databasePath,
    seedDemo: seedDemo,
    drawRunner: drawRunner,
  );
  await server.initializeDatabase();
  await server.initialize();
  return server;
}
