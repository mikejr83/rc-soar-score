import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/contest_authorization.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Where the self-scoring site lives, unless the server is told otherwise.
const defaultSelfScoringBaseUrl = 'https://score.rcsoarscore.com';

/// Adds the director's invitation routes to [router] (mounted under
/// `/api/v1`):
///
/// - `GET /contests/{id}/invitations` says which participations have an
///   active invitation, the link each one's QR code carries, and whether the
///   contest may issue more now ([ContestInvitationsDto]).
/// - `POST /contests/{id}/invitations` issues an invitation for each listed
///   participation that has none ([IssueInvitationsRequest]). It never sends
///   email (#790). A request that cannot complete (unknown participation,
///   contest not Configuring, Ready or Running, a participation that is not
///   a pilot) issues nothing. Repeating it, or asking for a pilot that has an
///   invitation, returns the same links.
///
/// Both need the contest's director. With [service] null (no invitation
/// secret) they answer 409 `invitations_not_available`. The links are
/// `{selfScoringBaseUrl}/invitations/{credential}`; they are secrets and
/// never logged.
void addInvitationRoutes(
  Router router,
  Repository repository, {
  required InvitationService? service,
  String selfScoringBaseUrl = defaultSelfScoringBaseUrl,
}) {
  final base = selfScoringBaseUrl.replaceAll(RegExp(r'/+$'), '');

  InvitationService requireService() =>
      service ??
      (throw ContestStateError(
        'invitations_not_available',
        'this server does not issue invitations',
      ));

  ContestInvitationDto dto(IssuedInvitation issued) => ContestInvitationDto(
    participationId: issued.invitation.contestParticipationId,
    link: '$base/invitations/${issued.credential}',
  );

  router.get('/contests/<id>/invitations', (Request request, String id) async {
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final invitations = requireService();
    final contest = (await repository.contestRepository.findById(contestId))!;
    final check = invitations.issuability(contest);
    final active = await invitations.activeForContest(contestId);
    return jsonResponse(
      ContestInvitationsDto(
        contestId: contestId,
        canIssue: check.canIssue,
        cannotIssueCode: check.code,
        cannotIssueReason: check.reason,
        invitations: active.links.map(dto).toList(),
        unreproducibleParticipationIds: active.unreproducible,
      ).toJson(),
    ).change(headers: {'cache-control': 'no-store'});
  });

  router.post('/contests/<id>/invitations', (Request request, String id) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    final invitations = requireService();
    final body = await readJsonBody(request, IssueInvitationsRequest.fromJson);
    if (body.requestId.trim().isEmpty ||
        body.participationIds.isEmpty ||
        body.participationIds.length >
            IssueInvitationsRequest.maxParticipations) {
      throw ArgumentError(
        'send a request id and 1 to '
        '${IssueInvitationsRequest.maxParticipations} participations',
      );
    }
    final issued = await invitations.issueMany(
      contestId: contestId,
      participationIds: body.participationIds,
      issuedBy: principal.accountId,
      requestId: body.requestId.trim(),
    );
    return jsonResponse(
      IssueInvitationsResponse(
        issuedCount: issued.where((i) => i.created).length,
        invitations: issued.map(dto).toList(),
      ).toJson(),
    ).change(headers: {'cache-control': 'no-store'});
  });
}
