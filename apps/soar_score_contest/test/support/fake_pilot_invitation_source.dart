import 'dart:async';

import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/pilot_invitations.dart';

class FakePilotInvitationSource implements PilotInvitationSource {
  FakePilotInvitationSource({
    this.links = const {},
    this.reason,
    this.failSend = false,
    this.failReadAfterSend = false,
    this.readGate,
    this.sendGate,
    this.email,
    this.emailStatus = const {},
  });

  /// What the email step reports, by participation id; `null` means no email
  /// was attempted. Called with the ids that were sent.
  final InvitationEmailReport Function(List<Id> ids)? email;

  /// Stored email statuses the read returns, by participation id.
  Map<String, String> emailStatus;

  final Completer<void>? readGate;
  final Completer<void>? sendGate;

  Map<String, String> links;
  final String? reason;
  final bool failSend;
  final bool failReadAfterSend;
  final sent = <List<Id>>[];
  var _sentOnce = false;

  @override
  Future<PilotInvitations> read(ApiClient client, Id contestId) async {
    await readGate?.future;
    if (failReadAfterSend && _sentOnce) {
      return const PilotInvitations(loadFailed: true);
    }
    return PilotInvitations(
      links: Map.of(links),
      emailStatus: Map.of(emailStatus),
      sendUnavailableReason: reason,
    );
  }

  @override
  Future<InvitationEmailReport> send(
    ApiClient client,
    Id contestId,
    List<Id> ids,
  ) async {
    await sendGate?.future;
    if (failSend) throw StateError('no');
    _sentOnce = true;
    sent.add(ids);
    links = {
      ...links,
      for (final id in ids) id.value: 'https://x.test/${id.value}',
    };
    return email?.call(ids) ?? const InvitationEmailReport.none();
  }
}
