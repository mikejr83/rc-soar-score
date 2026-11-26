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
/// - `POST /contests/{id}/invitations/email` emails the active invitation
///   link of each listed pilot who has an address ([EmailInvitationsRequest]).
///   The link exists whatever the outcome; a repeated request id sends
///   nothing again to a pilot already sent (a skipped pilot is judged afresh).
///   A director can start at most 300 new emails per contest per hour; past
///   that a pilot comes back `limited`. With [email] null it answers 409 `email_not_available`.
///
/// All need the contest's director. With [service] null (no invitation
/// secret) they answer 409 `invitations_not_available`. The links are
/// `{selfScoringBaseUrl}/invitations/{credential}`; they are secrets and
/// never logged.
void addInvitationRoutes(
  Router router,
  Repository repository, {
  required InvitationService? service,
  InvitationEmailService? email,
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
    emailStatus: _latestEmailStatus(issued.invitation),
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

  router.post('/contests/<id>/invitations/email', (
    Request request,
    String id,
  ) async {
    final principal = requirePrincipal(request);
    final contestId = Id.parse(id);
    await requireContestDirector(request, repository, contestId);
    requireService();
    final mail =
        email ??
        (throw ContestStateError(
          'email_not_available',
          'this server does not send invitation emails',
        ));
    final body = await readJsonBody(request, EmailInvitationsRequest.fromJson);
    if (body.requestId.trim().isEmpty ||
        body.participationIds.isEmpty ||
        body.participationIds.length >
            InvitationEmailService.maxParticipations) {
      throw ArgumentError(
        'send a request id and 1 to '
        '${InvitationEmailService.maxParticipations} participations',
      );
    }
    final results = await mail.emailMany(
      contestId: contestId,
      participationIds: body.participationIds,
      requestedBy: principal.accountId,
      requestId: body.requestId.trim(),
    );
    return jsonResponse(
      EmailInvitationsResponse(
        results: [
          for (final result in results)
            EmailInvitationResultDto(
              participationId: result.participationId,
              status: result.status?.wire,
              skipped: switch (result.skipped) {
                null => null,
                InvitationEmailSkip.noEmail => 'no_email',
                InvitationEmailSkip.noInvitation => 'no_invitation',
                InvitationEmailSkip.linkUnavailable => 'link_unavailable',
                InvitationEmailSkip.notPilot => 'not_pilot',
              },
              repeated: result.repeated,
            ),
        ],
      ).toJson(),
    ).change(headers: {'cache-control': 'no-store'});
  });
}

/// The status of the newest email outcome of [invitation], or null.
String? _latestEmailStatus(Invitation invitation) {
  for (final outcome in invitation.deliveryOutcomes.reversed) {
    if (outcome['channel'] == 'email') return outcome['status'] as String?;
  }
  return null;
}
