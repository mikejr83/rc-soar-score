import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart'
    show
        Id,
        Invitation,
        InvitationCodec,
        InvitationService,
        ParticipantAccess,
        ProtectedCredential,
        ParticipantScoresService,
        ParticipantSubmissionRefusal,
        ScoresService;
import 'package:soar_score_data/soar_score_data.dart';

import 'e2e_database.dart';

/// The secret the E2E server signs invitation links with. Public on purpose:
/// this server is never deployed.
const e2eInvitationSecret = 'e2e-invitation-secret-at-least-32-bytes-long';

/// The API server the web end-to-end tests run against.
///
/// NOT for deployment: it skips token checks, so every request acts as the
/// installation's Local account, exactly like the Windows build's embedded
/// server. It serves a fresh SQLite database with the system data and the
/// demo data, and allows cross-origin calls so the browser build can reach it.
///
///     dart run tool/e2e_server.dart [--port 8080] [--database <file>]
///         [--profile native|server]
///
/// `--profile native` (the default) is the contest app's installation
/// database with the demo data. `--profile server` is the hosted server's
/// profile with only the system data and one director account: the self
/// scoring app's journey (`scripts/e2e-score.sh`) needs it, because invitations
/// exist only on the hosted server.
/// `--publishing` adds the backend tables to the native profile as well, while
/// keeping its Local account and demo data for the contest lifecycle journey.
///
/// Without `--database` it uses a new temporary file, deleted on exit. It
/// prints `E2E_SERVER_READY <port>` once it listens; `scripts/e2e` waits for
/// that line.
///
/// Matrix draws are held for a few seconds (`DelayedDrawRunner`) so a journey
/// can see their progress and cancel one.
///
/// `POST /__e2e/fail-next-write` makes the next write (any method but GET,
/// HEAD and OPTIONS) answer 503 once, so a journey can check what the app
/// does when a save fails and then succeeds on Retry. Test-only, like the
/// rest of this server.
///
/// `POST /__e2e/pilot-submission` stores a pilot's own score the way the
/// self-scoring app's submission does (a preliminary `ScoreAttempt`; the row
/// shows the "Pilot entry" chip until the director saves), for a database that
/// has no invitations: the contest app's journeys run on the installation
/// profile, where a real invitation cannot exist. The body is
/// `{"contest_id", "participation_id", "round", "components"}`. The
/// submission is made through `ScoresService.submitParticipantScore` with a
/// made-up guest and invitation, so it is checked as a real one is. A
/// refusal (the pilot already has a score, say) answers 409 with its reason. Test-only,
/// like the rest of this server.
///
/// Invitations (the self-scoring app's links and guest sessions) are on, signed
/// with the fixed [e2eInvitationSecret]. `POST /__e2e/advance-clock?hours=N`
/// moves the invitation service's clock forward by N hours, so a journey can
/// reach the end of the 24 hours a completed contest's links stay open
/// without waiting. It moves only that clock (link expiry and guest sessions),
/// not stored timestamps. Test-only, like the rest of this server.
Future<void> main(List<String> args) async {
  final port = int.parse(_option(args, '--port') ?? '8080');
  final given = _option(args, '--database');
  final directory = given == null
      ? await Directory.systemTemp.createTemp('soar_score_e2e_')
      : null;
  final file = File(given ?? '${directory!.path}/soar_score_e2e.db');
  if (given != null && file.existsSync()) file.deleteSync();

  final serverProfile = (_option(args, '--profile') ?? 'native') == 'server';
  final publishingEnabled = args.contains('--publishing');
  final database = E2eDatabase(
    serverProfile
        ? NativeDatabase(file, enableMigrations: true)
        : NativeDatabase.createInBackground(file, enableMigrations: true),
    profile: serverProfile ? DatabaseProfile.server : DatabaseProfile.native,
    publishingEnabled: publishingEnabled,
  );
  final localAccountId = await seedE2eDatabase(
    database,
    serverProfile: serverProfile,
  );
  final repository = Repository(database);

  final clock = _AdvanceableClock();
  final inFlight = InFlightRequests();
  final handler = Pipeline()
      .addMiddleware(inFlight.middleware)
      .addMiddleware(_cors())
      .addMiddleware(_journeyLog())
      .addMiddleware(_failNextWrite())
      .addMiddleware(_advanceClock(clock))
      .addMiddleware(_pilotSubmission(repository))
      .addHandler(
        buildApiHandler(
          name: 'soar_score_e2e',
          displayName: 'Soar Score E2E test server',
          version: '0.0.0',
          schemaRevision: database.schemaVersion,
          repository: repository,
          publishingEnabled: publishingEnabled,
          // Only the service gets the advanceable clock: link and guest
          // session expiry are enforced inside it. The participant handler
          // keeps the real clock, which only sets the cookie's Max-Age at
          // resolve time; do not hand it this clock.
          invitations: InvitationService(
            repository,
            InvitationCodec.fromText(e2eInvitationSecret),
            clock: clock.now,
          ),
          authMiddleware: fixedPrincipal(Principal(accountId: localAccountId)),
          // Draws are held a few seconds so a journey can see their progress
          // and cancel one.
          drawRunner: const DelayedDrawRunner(IsolateDrawRunner()),
        ),
      );
  final server = await shelf_io.serve(
    handler,
    InternetAddress.loopbackIPv4,
    port,
  );

  Future<void> stop(ProcessSignal _) async {
    // Refuse new requests, let the running ones answer, and only then close
    // the database under them; force is the fallback for a stuck connection.
    final graceful = server.close();
    await inFlight.drain();
    try {
      await graceful.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      await server.close(force: true);
    }
    await database.close();
    if (directory != null) await directory.delete(recursive: true);
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(stop);
  if (!Platform.isWindows) ProcessSignal.sigterm.watch().listen(stop);
  stdout.writeln('E2E_SERVER_READY ${server.port}');
}

String? _option(List<String> args, String name) {
  final i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

/// Answers cross-origin calls from whatever origin the test app is served on.
/// The self-scoring app sends its guest cookie (`withCredentials`), and a
/// browser refuses a wildcard `Access-Control-Allow-Origin` for such a call, so
/// the request's own origin and headers are echoed and credentials allowed.
Map<String, String> _corsHeaders(Request request) => {
  'Access-Control-Allow-Origin': request.headers['origin'] ?? '*',
  'Access-Control-Allow-Credentials': 'true',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers':
      request.headers['access-control-request-headers'] ?? '*',
  'Vary': 'Origin',
};

Middleware _cors() =>
    (inner) => (request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders(request));
      }
      final response = await inner(request);
      return response.change(headers: _corsHeaders(request));
    };

/// `POST /__e2e/log` prints its body as a line starting `[E2E]`, so a journey
/// that runs in the browser (and prints nothing live) can show its progress
/// in this server's output; `scripts/e2e-contest.sh` echoes those lines.
Middleware _journeyLog() =>
    (inner) => (request) async {
      if (request.method == 'POST' && request.url.path == '__e2e/log') {
        stdout.writeln('[E2E] ${(await request.readAsString()).trim()}');
        return Response.ok('logged');
      }
      return inner(request);
    };

/// See `POST /__e2e/fail-next-write` in the library comment.
Middleware _failNextWrite() {
  var failNext = false;
  return (inner) => (request) async {
    if (request.method == 'POST' &&
        request.url.path == '__e2e/fail-next-write') {
      failNext = true;
      return Response.ok('The next write will fail.');
    }
    final isWrite = !{'GET', 'HEAD', 'OPTIONS'}.contains(request.method);
    if (failNext && isWrite) {
      failNext = false;
      return Response(
        503,
        headers: {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'error': {
            'code': 'unavailable',
            'message': 'The E2E server was told to fail this write.',
          },
        }),
      );
    }
    return inner(request);
  };
}

/// The invitation service's clock: real time plus whatever
/// `POST /__e2e/advance-clock` has added.
class _AdvanceableClock {
  Duration _offset = Duration.zero;

  DateTime now() => DateTime.now().toUtc().add(_offset);

  void advance(Duration by) => _offset += by;
}

/// See `POST /__e2e/advance-clock` in the library comment.
Middleware _advanceClock(_AdvanceableClock clock) =>
    (inner) => (request) async {
      if (request.method == 'POST' &&
          request.url.path == '__e2e/advance-clock') {
        final hours = int.tryParse(request.url.queryParameters['hours'] ?? '');
        if (hours == null || hours < 0) {
          return Response.badRequest(body: 'Pass ?hours=<whole hours>.');
        }
        clock.advance(Duration(hours: hours));
        return Response.ok('The invitation clock is now ${clock.now()}.');
      }
      return inner(request);
    };

/// See `POST /__e2e/pilot-submission` in the library comment.
Middleware _pilotSubmission(Repository repository) =>
    (inner) => (request) async {
      if (request.method != 'POST' ||
          request.url.path != '__e2e/pilot-submission') {
        return inner(request);
      }
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final contest = await repository.contestRepository.findById(
        Id.parse(body['contest_id'] as String),
      );
      final participation = await repository.contestParticipationRepository
          .findById(Id.parse(body['participation_id'] as String));
      if (contest == null || participation == null) {
        return Response.notFound('No such contest or participation.');
      }
      final latest = await repository.matrixRevisionRepository.latestForContest(
        contest.id,
      );
      if (latest == null) return Response.badRequest(body: 'No draw yet.');
      final guest = Id.create();
      final invitation = Invitation(
        id: Id.create(),
        contestId: contest.id,
        contestParticipationId: participation.id,
        protectedCredential: ProtectedCredential('e2e-no-real-credential'),
        issuedBy: guest,
        issuedAt: DateTime.now().toUtc(),
        clientMutationId: 'e2e-pilot-submission-${Id.create().value}',
      );
      final access = ParticipantAccess(
        guestAccountId: guest,
        invitation: invitation,
        participation: participation,
        contest: contest,
        readOnly: false,
      );
      try {
        await ScoresService(repository).submitParticipantScore(
          access,
          body['round'] as int,
          clientMutationId: 'e2e-pilot-${Id.create().value}',
          matrixRevision: latest.revisionNumber,
          components: Map<String, Object?>.from(body['components'] as Map),
          sourceDevice: 'e2e',
        );
      } on ParticipantSubmissionRefusal catch (refusal) {
        // Answered here so the browser can read it (an escaped error is a
        // 500 without CORS headers, which it reports as "Failed to fetch").
        return Response(409, body: '${refusal.code}: ${refusal.message}');
      }
      return Response(201, body: 'The pilot submission is stored.');
    };
