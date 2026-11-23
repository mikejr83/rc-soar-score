import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Adds the routes where a signed-in pilot sees and manages the link between
/// their account and a director's participant profile (#545 B) to [router]
/// (mounted under `/api/v1`):
///
/// - `GET /account/participations` lists the contests the account reaches
///   through its confirmed links, newest first ([AccountParticipationsDto]).
///   A later invitation of a linked profile appears with no further
///   confirmation.
/// - `GET /account/link-candidates` lists the "Is this you?" matches of the
///   account's verified email ([LinkCandidatesDto]); empty without one.
/// - `POST /account/link-candidates/{id}/confirm` says the candidate is the
///   caller ([AccountLinkDto]) and claims the entries their guest accounts
///   made, in one transaction. `{id}` is the candidate's `id`.
/// - `POST /account/link-candidates/{id}/decline` says it is not (204); it is
///   not offered again.
/// - `GET /account/links` lists the confirmed links ([AccountLinksDto]).
/// - `POST /account/links/{id}/end` ends one ([AccountLinkDto]). Nothing
///   published changes, and the invitations go back to their guests.
///
/// Reads use stored data only and write nothing. Every write is idempotent.
/// An unknown, foreign or no-longer-eligible id is 404 `link_not_found`;
/// another account that already holds the pilot is 409 `already_linked`.
/// Nothing here tells a director that an account exists, and no response
/// carries an email or a director.
///
/// With [invitations] null (no invitation secret) the routes answer 409
/// `invitations_not_available`, like the invitation routes. The hosted server
/// only: the embedded instance has no accounts and answers 409
/// `backend_only`.
void addAccountLinkRoutes(
  Router router,
  Repository repository, {
  required InvitationService? invitations,
}) {
  ParticipantLinkService service() => ParticipantLinkService(
    repository,
    invitations ??
        (throw ContestStateError(
          'invitations_not_available',
          'this server does not issue invitations',
        )),
  );

  Response answer(Map<String, dynamic> json) =>
      jsonResponse(json).change(headers: {'cache-control': 'no-store'});

  router.get('/account/participations', (Request request) async {
    final principal = requirePrincipal(request);
    final rows = await service().participationsFor(principal.accountId);
    return answer(
      AccountParticipationsDto(
        participations: [for (final row in rows) _participationDto(row)],
      ).toJson(),
    );
  });

  router.get('/account/link-candidates', (Request request) async {
    final principal = requirePrincipal(request);
    final candidates = await service().candidatesFor(principal.accountId);
    return answer(
      LinkCandidatesDto(
        candidates: [
          for (final c in candidates)
            LinkCandidateDto(
              id: c.profileId,
              firstName: c.firstName,
              lastName: c.lastName,
              contests: [
                for (final contest in c.contests)
                  LinkCandidateContestDto(
                    name: contest.name,
                    startDateTime: contest.startDateTime,
                    endDateTime: contest.endDateTime,
                    timezone: contest.timezone,
                    host: contest.host,
                    city: contest.city,
                    state: contest.state,
                    country: contest.country,
                  ),
              ],
            ),
        ],
      ).toJson(),
    );
  });

  router.post('/account/link-candidates/<id>/confirm', (
    Request request,
    String id,
  ) async {
    final principal = requirePrincipal(request);
    final link = await service().confirmCandidate(
      profileId: _candidateId(id),
      accountId: principal.accountId,
    );
    return answer((await _linkDtos(repository, [link])).single.toJson());
  });

  router.post('/account/link-candidates/<id>/decline', (
    Request request,
    String id,
  ) async {
    final principal = requirePrincipal(request);
    await service().declineCandidate(
      profileId: _candidateId(id),
      accountId: principal.accountId,
    );
    return Response(204, headers: {'cache-control': 'no-store'});
  });

  router.get('/account/links', (Request request) async {
    final principal = requirePrincipal(request);
    final links = await service().confirmedLinksFor(principal.accountId);
    return answer(
      AccountLinksDto(links: await _linkDtos(repository, links)).toJson(),
    );
  });

  router.post('/account/links/<id>/end', (Request request, String id) async {
    final principal = requirePrincipal(request);
    final ended = await service().end(
      linkId: _linkId(id),
      accountId: principal.accountId,
    );
    return answer((await _linkDtos(repository, [ended])).single.toJson());
  });
}

/// A path id that is not an id cannot be anyone's candidate or link: the same
/// answer as one that is not theirs.
Id _candidateId(String text) => _idOrNotFound(text);

Id _linkId(String text) => _idOrNotFound(text);

Id _idOrNotFound(String text) {
  try {
    return Id.parse(text);
  } on FormatException {
    throw ParticipantLinkError.linkNotFound();
  } on ArgumentError {
    throw ParticipantLinkError.linkNotFound();
  }
}

AccountParticipationDto _participationDto(LinkedParticipation row) {
  final contest = row.contest;
  return AccountParticipationDto(
    participationId: row.participationId,
    contestId: contest.id,
    contestName: contest.name,
    startDateTime: contest.startDateTime,
    endDateTime: contest.endDateTime,
    timezone: contest.timezone,
    phase: switch (contest.lifecycleState) {
      LifecycleState.completed => AccountParticipationPhase.completed,
      LifecycleState.running => AccountParticipationPhase.inProgress,
      _ => AccountParticipationPhase.invited,
    },
    readOnly: row.readOnly,
    host: contest.host,
    city: contest.city,
    state: contest.state,
    country: contest.country,
  );
}

/// The DTOs of [links], with the pilots' names read in one lookup.
Future<List<AccountLinkDto>> _linkDtos(
  Repository repository,
  List<ParticipantAccountLink> links,
) async {
  final profiles = await repository.participantProfileRepository.findByIds({
    for (final link in links) link.participantProfileId,
  });
  return [
    for (final link in links)
      AccountLinkDto(
        id: link.id,
        pilotName: [
          profiles[link.participantProfileId]?.firstName,
          profiles[link.participantProfileId]?.lastName,
        ].whereType<String>().join(' '),
        status: link.status,
        origin: link.origin,
        confirmedAt: link.confirmedAt,
        endedAt: link.endedAt,
      ),
  ];
}
