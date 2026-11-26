import 'package:flutter/foundation.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Whether [participation] can have an invitation: a pilot. A retired pilot
/// still can, so a director can send or copy the link whatever the pilot's
/// state; the server only checks the role. The workspace and the Participants
/// list share this rule, so neither issues or shows a link for a non-flying
/// participant.
bool canHaveInvitation(ContestParticipation participation) =>
    participation.roleType == RoleType.pilot;

/// What the last send did for one pilot's email. The link is issued whatever
/// this says: it only tells the director whether to pass the link on another
/// way. `accepted` means the mail service took the message, not that the
/// pilot has read it.
enum InvitationEmailKind {
  /// The mail service accepted the message.
  emailed,

  /// The pilot has no email address on file, so only the link exists.
  noAddress,

  /// Not sent: the mail service refused it, could not send now, or the
  /// pilot's address bounced afterwards.
  notSent,

  /// The hourly limit of new emails for the contest was reached.
  limitReached,

  /// The send may or may not have gone out.
  unknown,
}

/// The kind a stored email status (`accepted`, `rejected`, ...) stands for,
/// or `null` for a status this app does not know.
InvitationEmailKind? emailKindOfStatus(String? status) => switch (status) {
  'accepted' => InvitationEmailKind.emailed,
  'rejected' ||
  'unavailable' ||
  'bounced' ||
  'complained' => InvitationEmailKind.notSent,
  'limited' => InvitationEmailKind.limitReached,
  'sending' || 'unconfirmed' => InvitationEmailKind.unknown,
  _ => null,
};

/// What a send did about email, by participation id.
class InvitationEmailReport {
  const InvitationEmailReport({
    this.kinds = const {},
    this.serviceUnavailable = false,
  });

  /// No email was attempted (a source that has none, or nothing to email).
  const InvitationEmailReport.none() : this();

  /// The links were issued but the server could not be asked to email them.
  const InvitationEmailReport.unavailable()
    : kinds = const {},
      serviceUnavailable = true;

  final Map<String, InvitationEmailKind> kinds;

  /// The email step could not run at all (the server cannot send email, or the
  /// request failed): every pilot keeps the link, nobody was emailed.
  final bool serviceUnavailable;

  InvitationEmailKind? kindOf(Id participation) => kinds[participation.value];

  int count(InvitationEmailKind kind) =>
      kinds.values.where((value) => value == kind).length;

  /// Pilots whose email did not go out, so the director should pass their
  /// link on another way.
  List<String> get needAnotherWay => [
    for (final entry in kinds.entries)
      if (entry.value != InvitationEmailKind.emailed) entry.key,
  ];

  bool get isEmpty => kinds.isEmpty && !serviceUnavailable;
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
    this.emailStatus = const {},
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

  /// The latest email status stored for each participation that was ever
  /// emailed (`accepted`, `rejected`, ...), by participation id.
  final Map<String, String> emailStatus;

  /// What the latest email for [participation] did, or `null` when it was
  /// never emailed.
  InvitationEmailKind? emailKindOf(Id participation) =>
      emailKindOfStatus(emailStatus[participation.value]);

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

  /// Sends invitations to [participations]: issues a link for each that has
  /// none, then emails every pilot who has an address their link (again, for a
  /// pilot emailed before). The links never depend on the email: throws only
  /// when nothing could be issued, and answers how the email step went.
  Future<InvitationEmailReport> send(
    ApiClient client,
    Id contestId,
    List<Id> participations,
  );
}

/// The stand-in until the API exists: nobody has an invitation, and sending is
/// unavailable with a reason in text. Cards print without QR codes.
class UnavailablePilotInvitationSource implements PilotInvitationSource {
  const UnavailablePilotInvitationSource();

  @override
  Future<PilotInvitations> read(ApiClient client, Id contestId) async =>
      const PilotInvitations(sendUnavailable: SendUnavailable.notInThisVersion);

  @override
  Future<InvitationEmailReport> send(
    ApiClient client,
    Id contestId,
    List<Id> participations,
  ) => Future.error(StateError('Sending invitations is not available.'));
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
      return PilotInvitations(
        links: links,
        emailStatus: {
          for (final invitation in answer.invitations)
            if (invitation.emailStatus != null)
              invitation.participationId.value: invitation.emailStatus!,
        },
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
  Future<InvitationEmailReport> send(
    ApiClient client,
    Id contestId,
    List<Id> participations,
  ) async {
    // Links first: they are the invitation. A failure here is a failed send.
    await client.issueInvitations(
      contestId,
      IssueInvitationsRequest(
        requestId: Id.create().value,
        participationIds: participations,
      ),
    );
    // Then the email, one request id per press so a retry of this very call
    // cannot send twice. Whatever happens here, the links exist.
    try {
      final answer = await client.emailInvitations(
        contestId,
        EmailInvitationsRequest(
          requestId: Id.create().value,
          participationIds: participations,
        ),
      );
      return InvitationEmailReport(
        kinds: {
          for (final result in answer.results)
            result.participationId.value: _kindOf(result),
        },
      );
    } on ApiException {
      return const InvitationEmailReport.unavailable();
    }
  }

  static InvitationEmailKind _kindOf(EmailInvitationResultDto result) =>
      switch (result.skipped) {
        'no_email' => InvitationEmailKind.noAddress,
        null => emailKindOfStatus(result.status) ?? InvitationEmailKind.unknown,
        _ => InvitationEmailKind.notSent,
      };
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
  InvitationEmailReport _lastEmail = const InvitationEmailReport.none();
  InvitationPhase _phase;
  bool _disposed = false;

  PilotInvitations get invitations => _invitations;
  InvitationPhase get phase => _phase;
  bool get sending => _phase == InvitationPhase.sending;

  /// How the email step of the last send went.
  InvitationEmailReport get lastEmail => _lastEmail;

  bool has(Id participation) => _invitations.has(participation);

  /// Sends invitations to [participations] and reads the invitations again.
  /// Completes with whether it worked; nothing is added when it did not.
  Future<bool> send(List<Id> participations) async {
    if (sending) {
      return false;
    }
    _set(InvitationPhase.sending);
    _lastEmail = const InvitationEmailReport.none();
    try {
      _lastEmail = await source.send(client, contestId, participations);
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
