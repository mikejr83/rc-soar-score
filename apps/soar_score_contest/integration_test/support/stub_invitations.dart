import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/pilot_invitations.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Stands in for the hosted server's invitations, which a journey on the
/// embedded server cannot reach: sending issues a link per pilot, once, and
/// every later read returns the same link, as the real API does (#589).
///
/// Swap it in with `PilotInvitationSources.current` for the length of a step
/// and put the old source back afterwards.
class StubPilotInvitationSource implements PilotInvitationSource {
  final Map<String, String> _links = {};

  /// How many sends issued at least one new invitation.
  int issuingSends = 0;

  /// The email address each pilot has, by participation id, as the real
  /// server reads it from the profile. A pilot not listed has none.
  final Map<String, String> addresses = {};

  /// The kind the stand-in mail service answers for an address; `emailed`
  /// unless a journey step scripts a failure.
  InvitationEmailKind mailAnswer = InvitationEmailKind.emailed;

  /// Every email sent, by participation id, one entry per send that went out.
  final emailsSent = <String>[];

  final Map<String, String> _statuses = {};

  static String linkFor(Id participation) =>
      'https://score.example.test/invitations/${participation.value}';

  @override
  Future<PilotInvitations> read(ApiClient client, Id contestId) async =>
      PilotInvitations(links: Map.of(_links), emailStatus: Map.of(_statuses));

  @override
  Future<InvitationEmailReport> send(
    ApiClient client,
    Id contestId,
    List<Id> participations,
  ) async {
    final before = _links.length;
    for (final id in participations) {
      _links.putIfAbsent(id.value, () => linkFor(id));
    }
    if (_links.length > before) issuingSends++;
    final kinds = <String, InvitationEmailKind>{};
    for (final id in participations) {
      if (!addresses.containsKey(id.value)) {
        kinds[id.value] = InvitationEmailKind.noAddress;
        continue;
      }
      kinds[id.value] = mailAnswer;
      _statuses[id.value] = switch (mailAnswer) {
        InvitationEmailKind.emailed => 'accepted',
        InvitationEmailKind.limitReached => 'limited',
        InvitationEmailKind.unknown => 'unconfirmed',
        _ => 'rejected',
      };
      if (mailAnswer == InvitationEmailKind.emailed) emailsSent.add(id.value);
    }
    return InvitationEmailReport(kinds: kinds);
  }
}
