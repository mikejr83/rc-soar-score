import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' hide Repository;
import 'package:http/http.dart' as http;
import 'package:soar_score_data/soar_score_data.dart';

import 'auth/auth0_token_verifier.dart';
import 'auth/auth0_user_profile_source.dart';
import 'config/server_config.dart';
import 'mail/invitation_mailer.dart';
import 'mail/ses_feedback/ses_feedback_handler.dart';
import 'mail/ses_feedback/sns_verifier.dart';
import 'mail/ses_v2_sender.dart';
import 'support/support_wiring.dart';
import 'handler.dart';

final _logger = Logger('Server');

/// A started server: the listener plus the database behind it.
class RunningServer {
  RunningServer._(this._server, this._database, this._recovery, this._upstream);

  final HttpServer _server;
  final SoarScoreDatabase _database;
  final Future<void> _recovery;

  /// The outbound client support mail and Turnstile share; closed on shutdown.
  final http.Client _upstream;
  Future<void>? _closing;

  /// The port the server listens on.
  int get port => _server.port;

  /// Stops accepting connections, lets running requests finish for up to
  /// [grace], then closes the database. Safe to call more than once.
  Future<void> close({Duration grace = const Duration(seconds: 10)}) =>
      _closing ??= _close(grace);

  Future<void> _close(Duration grace) async {
    _logger.info('Shutting down.');
    final closing = _server.close();
    try {
      await closing.timeout(grace);
    } on TimeoutException {
      _logger.warning('Requests still running after $grace; closing them.');
      await _server.close(force: true);
    }
    // A recovery pass still running must end before its database closes.
    await _recovery;
    _upstream.close();
    await _database.close();
    _logger.info('Shutdown complete.');
  }
}

/// Installs the shipped system data (landing tables, discipline profiles and
/// roles) into [database]; pass it as `onDatabaseOpen` to [startServer].
///
/// A failure stops startup, so the server never serves partial system data.
Future<void> seedSystemData(SoarScoreDatabase database) async {
  final outcome = await SystemDataSeeder(database).seed();
  _logger.info('System data ${outcome.name}.');
}

/// Opens the database, migrates it, and starts serving.
///
/// The database is [database] when given (tests), otherwise PostgreSQL from
/// [config]. It is opened first, so a bad connection or failed migration
/// fails here, before the port opens. [onDatabaseOpen] runs after the
/// migration and before the first request, which is where startup work such
/// as seeding system data belongs.
///
/// Every `/api/v1` request must carry an Auth0 access token for
/// `config.auth0Domain` and `config.apiAudience`. Tests pass [authMiddleware]
/// to use their own verifier.
Future<RunningServer> startServer(
  ServerConfig config, {
  SoarScoreDatabase? database,
  FutureOr<void> Function(SoarScoreDatabase database)? onDatabaseOpen,
  InternetAddress? address,
  AuthMiddleware? authMiddleware,
}) async {
  final db =
      database ??
      createPostgresDatabase(
        config.postgres,
        logStatementDurations: config.logStatementDurations,
      );
  final upstream = http.Client();
  try {
    await db.doWhenOpened((_) {});
    _logger.info('Database open and migrated.');
    await onDatabaseOpen?.call(db);
    final support = config.support;
    if (support == null) {
      _logger.warning('Public support endpoint disabled: settings incomplete.');
    }
    if (config.mail == null) {
      _logger.warning('Invitation email disabled: mail settings incomplete.');
    }
    final feedbackTopic = config.sesFeedbackTopic;
    if (feedbackTopic == null) {
      _logger.warning('SES feedback endpoint disabled: no topic configured.');
    }
    final server = await shelf_io.serve(
      createServerHandler(
        db,
        authMiddleware: authMiddleware ?? _auth0Middleware(config, db),
        corsAllowedOrigins: config.corsAllowedOrigins,
        invitationSecret: config.invitationSecret,
        selfScoringBaseUrl: config.selfScoringBaseUrl,
        trustedProxySecret: config.trustedProxySecret,
        invitationMailer: config.mail == null
            ? null
            : SesInvitationMailer(
                SesV2Sender(
                  client: upstream,
                  credentials: config.mail!.sesCredentials,
                  mode: config.mail!.mode,
                ),
              ),
        sesFeedbackHandler: feedbackTopic == null
            ? null
            : (feedback) => sesFeedbackHandler(
                verifier: SnsVerifier(topic: feedbackTopic, client: upstream),
                feedback: feedback,
                client: upstream,
              ),
        supportHandler: support == null
            ? null
            : supportHandlerFor(
                support,
                db,
                http: upstream,
                trustedProxySecret: config.trustedProxySecret,
              ),
      ),
      address ?? InternetAddress.anyIPv4,
      config.port,
    );
    _logger.info('Listening on port ${server.port}.');
    return RunningServer._(server, db, _recoverOfficialization(db), upstream);
  } catch (_) {
    upstream.close();
    await db.close();
    rethrow;
  }
}

/// Repeats the automatic officialization the last run may have left unfinished
/// (see [ScoresService.recoverAutomaticOfficialization]). It runs beside the
/// first requests and never fails the server.
Future<void> _recoverOfficialization(SoarScoreDatabase database) async {
  try {
    final changed = await ScoresService(Repository(database))
        .recoverAutomaticOfficialization();
    _logger.info('Automatic officialization recovered in $changed contests.');
  } on Object catch (error, stackTrace) {
    _logger.warning(
      'Automatic officialization recovery failed',
      error,
      stackTrace,
    );
  }
}

/// The bearer-token layer for Auth0 tokens, with accounts kept in [database].
AuthMiddleware _auth0Middleware(
  ServerConfig config,
  SoarScoreDatabase database,
) {
  final repository = Repository(database);
  return bearerAuth(
    verifier: Auth0TokenVerifier(
      domain: config.auth0Domain,
      audience: config.apiAudience,
    ),
    resolver: AccountPrincipalResolver(
      accounts: repository.accountRepository,
      identities: repository.accountIdentityRepository,
      profiles: Auth0UserProfileSource(domain: config.auth0Domain),
    ),
  );
}
