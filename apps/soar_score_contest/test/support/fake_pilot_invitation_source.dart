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
  });

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
      sendUnavailableReason: reason,
    );
  }

  @override
  Future<void> send(ApiClient client, Id contestId, List<Id> ids) async {
    await sendGate?.future;
    if (failSend) throw StateError('no');
    _sentOnce = true;
    sent.add(ids);
    links = {
      ...links,
      for (final id in ids) id.value: 'https://x.test/${id.value}',
    };
  }
}
