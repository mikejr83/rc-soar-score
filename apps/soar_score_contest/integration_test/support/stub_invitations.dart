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

  static String linkFor(Id participation) =>
      'https://score.example.test/invitations/${participation.value}';

  @override
  Future<PilotInvitations> read(ApiClient client, Id contestId) async =>
      PilotInvitations(links: Map.of(_links));

  @override
  Future<void> send(
    ApiClient client,
    Id contestId,
    List<Id> participations,
  ) async {
    final before = _links.length;
    for (final id in participations) {
      _links.putIfAbsent(id.value, () => linkFor(id));
    }
    if (_links.length > before) issuingSends++;
  }
}
