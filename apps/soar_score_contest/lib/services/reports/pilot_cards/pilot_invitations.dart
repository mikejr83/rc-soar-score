import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

final _logger = Logger('PilotInvitations');

/// Writes each invitation link to the log, so a developer can copy one from
/// the console and open it. A link opens a pilot's scoring page, so this is for
/// debug and profile builds only and a release build logs nothing.
void logInvitationLinks(Id contestId, Map<String, String> links) {
  if (kReleaseMode || links.isEmpty) return;
  final lines = [for (final e in links.entries) '  ${e.key}: ${e.value}'];
  _logger.info(
    'Invitation links of contest ${contestId.value} (development builds only):'
    '\n${lines.join('\n')}',
  );
}

/// The invitations a contest has issued, as the cards need them: for each
/// pilot that has one, the link its QR code carries.
///
/// A pilot's invitation is the same link an emailed invitation carries. It
/// never changes once issued, so a reprinted card shows the same code.
/// Why invitations cannot be sent, when the app itself knows. The server's own
/// reason (a contest that may not issue now) is [PilotInvitations.sendUnavailableReason].
enum SendUnavailable {
  /// Nobody is signed in, so the hosted server refused the call.
  signIn,

  /// The server issues no invitations.
  serverIssuesNone,

  /// Existing links cannot be shown because the server's secret changed.
  linksUnreproducible,

  /// This build has no invitation support.
  notInThisVersion,
}

class PilotInvitations {
  const PilotInvitations({
    this.links = const {},
    this.synchronized = true,
    this.sendUnavailable,
    this.sendUnavailableReason,
    this.loadFailed = false,
  });

  /// True when the invitations could not be read. The report stays printable
  /// (cards without QR codes) and offers a retry.
  final bool loadFailed;

  /// The invitation link by participation id.
  final Map<String, String> links;

  /// False for a contest organized offline that has not synchronized yet: no
  /// QR codes can be made until it has.
  final bool synchronized;

  /// Why invitations cannot be sent now when the app knows, or `null`.
  final SendUnavailable? sendUnavailable;

  /// Why invitations cannot be sent now in the server's words (a contest that
  /// is not Configuring, Ready or Running), or `null`.
  final String? sendUnavailableReason;

  /// Sending is not possible now, for whichever reason.
  bool get cannotSend =>
      sendUnavailable != null || sendUnavailableReason != null;

  bool has(Id participation) => links.containsKey(participation.value);

  String? linkOf(Id participation) => links[participation.value];
}

/// Where the cards read and issue pilot invitations. [ApiPilotInvitationSource]
/// is the real one; the report is built against this seam so tests and the
/// stand-ins can replace it without touching a page.
abstract interface class PilotInvitationSource {
  /// The invitations issued for [contestId].
  Future<PilotInvitations> read(ApiClient client, Id contestId);

  /// Issues an invitation for each of [participations] that has none. Never
  /// emails (#790). Throws when nothing could be issued.
  Future<void> send(ApiClient client, Id contestId, List<Id> participations);
}

/// The stand-in until the API exists: nobody has an invitation, and sending is
/// unavailable with a reason in text. Cards print without QR codes.
class UnavailablePilotInvitationSource implements PilotInvitationSource {
  const UnavailablePilotInvitationSource();

  @override
  Future<PilotInvitations> read(ApiClient client, Id contestId) async =>
      const PilotInvitations(sendUnavailable: SendUnavailable.notInThisVersion);

  @override
  Future<void> send(ApiClient client, Id contestId, List<Id> participations) =>
      Future.error(StateError('Sending invitations is not available.'));
}

/// The invitations API of the server the client talks to (#589):
/// `GET`/`POST /contests/{id}/invitations`. Issuing sends no email.
///
/// Only the hosted server issues invitations. A contest it has not
/// synchronized (404) reads as not synchronized, a server that issues none
/// (409 `invitations_not_available`) or a missing sign-in (401) reads as send
/// unavailable with the reason in text, and a contest that may not issue now
/// carries the server's reason.
class ApiPilotInvitationSource implements PilotInvitationSource {
  const ApiPilotInvitationSource();

  @override
  Future<PilotInvitations> read(ApiClient client, Id contestId) async {
    try {
      final answer = await client.contestInvitations(contestId);
      final links = {
        for (final invitation in answer.invitations)
          invitation.participationId.value: invitation.link,
      };
      logInvitationLinks(contestId, links);
      return PilotInvitations(
        links: links,
        sendUnavailableReason: answer.canIssue
            ? null
            : answer.cannotIssueReason,
        sendUnavailable:
            answer.canIssue && answer.unreproducibleParticipationIds.isNotEmpty
            ? SendUnavailable.linksUnreproducible
            : null,
      );
    } on ApiHttpError catch (error) {
      switch (error.statusCode) {
        case 404:
          return const PilotInvitations(synchronized: false);
        case 401:
          return const PilotInvitations(
            sendUnavailable: SendUnavailable.signIn,
          );
        case 409 when error.error?.code == 'invitations_not_available':
          return const PilotInvitations(
            sendUnavailable: SendUnavailable.serverIssuesNone,
          );
      }
      return const PilotInvitations(loadFailed: true);
    } on ApiException {
      return const PilotInvitations(loadFailed: true);
    }
  }

  @override
  Future<void> send(ApiClient client, Id contestId, List<Id> participations) =>
      client.issueInvitations(
        contestId,
        IssueInvitationsRequest(
          requestId: Id.create().value,
          participationIds: participations,
        ),
      );
}

/// The source the cards use. Held here so an E2E journey or a test can swap
/// it, as `ReportPrinters.current` does for the print dialogs.
abstract final class PilotInvitationSources {
  static PilotInvitationSource current = const ApiPilotInvitationSource();
}

/// Where sending invitations from the report stands.
enum InvitationPhase {
  idle,
  sending,

  /// Nothing was sent.
  failed,

  /// Sent, and the cards now have their QR codes.
  sent,

  /// Created, but the invitations could not be read afterwards, so the cards
  /// do not show the QR codes yet. Creating them again is not needed.
  sentNotLoaded,

  /// The invitations could not be read when the report opened.
  loadFailed,
}

/// The invitations of one open report and the send in progress. The report's
/// banner, print reminder and cards read it, and it tells them when it changes.
class PilotInvitationSession extends ChangeNotifier {
  PilotInvitationSession({
    required this.source,
    required this.client,
    required this.contestId,
    required PilotInvitations initial,
  }) : _invitations = initial,
       _phase = initial.loadFailed
           ? InvitationPhase.loadFailed
           : InvitationPhase.idle;

  /// Reads the invitations of [contestId] and starts a session on them. A read
  /// that fails starts the session in [InvitationPhase.loadFailed].
  static Future<PilotInvitationSession> open({
    required PilotInvitationSource source,
    required ApiClient client,
    required Id contestId,
  }) async {
    PilotInvitations initial;
    try {
      initial = await source.read(client, contestId);
    } on Object {
      initial = const PilotInvitations(loadFailed: true);
    }
    return PilotInvitationSession(
      source: source,
      client: client,
      contestId: contestId,
      initial: initial,
    );
  }

  final PilotInvitationSource source;
  final ApiClient client;
  final Id contestId;

  PilotInvitations _invitations;
  InvitationPhase _phase;
  bool _disposed = false;

  PilotInvitations get invitations => _invitations;
  InvitationPhase get phase => _phase;
  bool get sending => _phase == InvitationPhase.sending;

  bool has(Id participation) => _invitations.has(participation);

  /// Sends invitations to [participations] and reads the invitations again.
  /// Completes with whether it worked; nothing is added when it did not.
  Future<bool> send(List<Id> participations) async {
    if (sending) {
      return false;
    }
    _set(InvitationPhase.sending);
    try {
      await source.send(client, contestId, participations);
    } on Object {
      if (!_disposed) {
        _set(InvitationPhase.failed);
      }
      return false;
    }
    // The send worked. Reading the invitations back is a separate step: if it
    // fails the invitations are still out, so this is not a failed send.
    return _load(InvitationPhase.sent, InvitationPhase.sentNotLoaded);
  }

  /// Reads the invitations again after a send whose read-back failed.
  Future<bool> reload() async {
    if (sending) {
      return false;
    }
    final opening = _phase == InvitationPhase.loadFailed;
    _set(InvitationPhase.sending);
    return opening
        ? _load(InvitationPhase.idle, InvitationPhase.loadFailed)
        : _load(InvitationPhase.sent, InvitationPhase.sentNotLoaded);
  }

  Future<bool> _load(InvitationPhase ok, InvitationPhase failed) async {
    try {
      final fresh = await source.read(client, contestId);
      if (_disposed) {
        return false;
      }
      if (fresh.loadFailed) {
        _set(failed);
        return false;
      }
      _invitations = fresh;
      _set(ok);
      return true;
    } on Object {
      if (!_disposed) {
        _set(failed);
      }
      return false;
    }
  }

  /// Takes the "sent" confirmation down.
  void dismissSent() {
    if (_phase == InvitationPhase.sent) {
      _set(InvitationPhase.idle);
    }
  }

  void _set(InvitationPhase phase) {
    _phase = phase;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
