import 'package:flutter/foundation.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// The invitations a contest has issued, as the cards need them: for each
/// pilot that has one, the link its QR code carries.
///
/// A pilot's invitation is the same link an emailed invitation carries. It
/// never changes once issued, so a reprinted card shows the same code.
class PilotInvitations {
  const PilotInvitations({
    this.links = const {},
    this.synchronized = true,
    this.sendUnavailableReason,
  });

  /// The invitation link by participation id.
  final Map<String, String> links;

  /// False for a contest organized offline that has not synchronized yet: no
  /// QR codes can be made until it has.
  final bool synchronized;

  /// Why invitations cannot be sent now, or `null` when they can.
  final String? sendUnavailableReason;

  bool has(Id participation) => links.containsKey(participation.value);

  String? linkOf(Id participation) => links[participation.value];
}

/// Where the cards read and issue pilot invitations. The server has no
/// endpoint for either yet (tracked in the issue named in
/// [UnavailablePilotInvitationSource]); the report is built against this
/// seam so the API-backed source replaces the stub without touching a page.
abstract interface class PilotInvitationSource {
  /// The invitations issued for [contestId].
  Future<PilotInvitations> read(ApiClient client, Id contestId);

  /// Issues an invitation for each of [participations] that has none and sends
  /// the emails. Throws when nothing could be sent.
  Future<void> send(ApiClient client, Id contestId, List<Id> participations);
}

/// The stand-in until the API exists: nobody has an invitation, and sending is
/// unavailable with a reason in text. Cards print without QR codes.
class UnavailablePilotInvitationSource implements PilotInvitationSource {
  const UnavailablePilotInvitationSource();

  static const reason =
      'Sending invitations isn’t available in this version of the app yet.';

  @override
  Future<PilotInvitations> read(ApiClient client, Id contestId) async =>
      const PilotInvitations(sendUnavailableReason: reason);

  @override
  Future<void> send(ApiClient client, Id contestId, List<Id> participations) =>
      Future.error(StateError(reason));
}

/// A placeholder until the API exists (#589): every pilot of the contest gets
/// the same QR code, which opens the project's web site, so the cards can be
/// seen and printed with a code. It is not an invitation: scanning it does not
/// open a pilot's scoring page, and nothing can be sent.
class PlaceholderPilotInvitationSource implements PilotInvitationSource {
  const PlaceholderPilotInvitationSource();

  static const link = 'https://score.rcsoarscore.com';

  @override
  Future<PilotInvitations> read(ApiClient client, Id contestId) async {
    final participations = await client.participations(contestId);
    return PilotInvitations(
      links: {for (final p in participations) p.id.value: link},
      sendUnavailableReason: UnavailablePilotInvitationSource.reason,
    );
  }

  @override
  Future<void> send(ApiClient client, Id contestId, List<Id> participations) =>
      Future.error(StateError(UnavailablePilotInvitationSource.reason));
}

/// The source the cards use. Held here so an E2E journey or a test can swap
/// it, as `ReportPrinters.current` does for the print dialogs.
abstract final class PilotInvitationSources {
  static PilotInvitationSource current =
      const PlaceholderPilotInvitationSource();
}

/// Where sending invitations from the report stands.
enum InvitationPhase { idle, sending, failed, sent }

/// The invitations of one open report and the send in progress. The report's
/// banner, print reminder and cards read it, and it tells them when it changes.
class PilotInvitationSession extends ChangeNotifier {
  PilotInvitationSession({
    required this.source,
    required this.client,
    required this.contestId,
    required PilotInvitations initial,
  }) : _invitations = initial;

  final PilotInvitationSource source;
  final ApiClient client;
  final Id contestId;

  PilotInvitations _invitations;
  InvitationPhase _phase = InvitationPhase.idle;
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
      final fresh = await source.read(client, contestId);
      if (_disposed) {
        return false;
      }
      _invitations = fresh;
      _set(InvitationPhase.sent);
      return true;
    } on Object {
      if (!_disposed) {
        _set(InvitationPhase.failed);
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
