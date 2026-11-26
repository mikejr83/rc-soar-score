import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/invitation_handlers.dart'
    show defaultPublicSiteBaseUrl;
import 'package:soar_score_api_handlers/handlers/participant_handlers.dart'
    show resolutionResponse;
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_api_handlers/middleware/client_address.dart';
import 'package:soar_score_api_handlers/middleware/error_mapping.dart';
import 'package:soar_score_api_handlers/middleware/invitation_throttle.dart';
import 'package:soar_score_api_handlers/middleware/request_id.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Adds the routes where a signed-in pilot sees and manages the link between
/// their account and a director's participant profile (#545 B) to [router]
/// (mounted under `/api/v1`):
///
/// - `GET /account/participations` lists the contests the account reaches
///   through its confirmed links, newest first ([AccountParticipationsDto]).
///   A later invitation of a linked profile appears with no further
///   confirmation.
/// - `GET /account/history` lists the finished contests the account reaches
///   through its confirmed links, once their read-only window on the list
///   above is over; no invitation needed ([AccountHistoryDto]). Paged with
///   `limit` (1 to 100, default 50) and `offset`; `next_offset` is null on
///   the last page. A contest reached only through an ended link is not
///   listed.
/// - `GET /account/link-candidates` lists the "Is this you?" matches of the
///   account's verified email ([LinkCandidatesDto]); empty without one.
/// - `POST /account/link-candidates/{id}/confirm` says the candidate is the
///   caller ([AccountLinkDto]) and claims the entries their guest accounts
///   made, in one transaction. `{id}` is the candidate's own `id`, not a profile id.
/// - `POST /account/link-candidates/{id}/decline` says it is not (204); it is
///   not offered again.
/// - `GET /account/links` lists the confirmed links ([AccountLinksDto]).
/// - `POST /account/links/{id}/end` ends one ([AccountLinkDto]). Nothing
///   published changes, and the invitations go back to their guests.
///
/// - `POST /account/invitation-claims` with a [ResolveInvitationRequest]
///   ("Continue as _name_?" after opening a link while signed in) links the
///   account to the pilot the link is for, claims the guests' entries and
///   answers a [ResolveInvitationResponse]: the session, acting as the
///   account, in the cookie for the web app. A link that does not open is the
///   same 404 `invalid_invitation` and 429 `rate_limited` as opening it
///   anonymously, counted by the same [InvitationThrottle].
/// - `POST /account/participations/{id}/session` opens a contest of the
///   participations list the same way, with no body; 404 `link_not_found`
///   for a participation that is not on the caller's list.
///
/// Each participation carries `public_results_url` when the contest is
/// published and public (the apex site's results page, [publicSiteBaseUrl]),
/// and null otherwise.
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
  InvitationThrottle? throttle,
  String? trustedProxySecret,
  DateTime Function()? clock,
  String publicSiteBaseUrl = defaultPublicSiteBaseUrl,
}) {
  final limits = throttle ?? InvitationThrottle();
  final now = clock ?? DateTime.now;
  final built = invitations == null
      ? null
      : ParticipantLinkService(repository, invitations);

  Future<ParticipantLinkService> service() async {
    if (built != null) return built;
    // An installation has no link tables at all: say so (`backend_only`)
    // before blaming the missing invitation secret.
    await repository.participantAccountLinkRepository.findById(Id.create());
    throw ContestStateError(
      'invitations_not_available',
      'this server does not issue invitations',
    );
  }

  Response answer(Map<String, dynamic> json) =>
      jsonResponse(json).change(headers: {'cache-control': 'no-store'});

  router.get('/account/participations', (Request request) async {
    final principal = requirePrincipal(request);
    final rows = await (await service()).participationsFor(principal.accountId);
    final addresses = await _publicResultsUrls(repository, publicSiteBaseUrl, {
      for (final row in rows) row.contest.id,
    });
    return answer(
      AccountParticipationsDto(
        participations: [
          for (final row in rows)
            _participationDto(row, addresses[row.contest.id]),
        ],
      ).toJson(),
    );
  });

  router.get('/account/history', (Request request) async {
    final principal = requirePrincipal(request);
    final limit = _pageNumber(request, 'limit', fallback: 50, min: 1, max: 100);
    final offset = _pageNumber(request, 'offset', fallback: 0, min: 0);
    final page = await (await service()).historyFor(
      principal.accountId,
      limit: limit,
      offset: offset,
    );
    final addresses = await _publicResultsUrls(repository, publicSiteBaseUrl, {
      for (final row in page.rows) row.contest.id,
    });
    return answer(
      AccountHistoryDto(
        contests: [
          for (final row in page.rows)
            _historyDto(row, addresses[row.contest.id]),
        ],
        nextOffset: page.hasMore ? offset + page.rows.length : null,
      ).toJson(),
    );
  });

  router.get('/account/link-candidates', (Request request) async {
    final principal = requirePrincipal(request);
    final candidates = await (await service()).candidatesFor(
      principal.accountId,
    );
    return answer(
      LinkCandidatesDto(
        candidates: [
          for (final c in candidates)
            LinkCandidateDto(
              id: c.id,
              firstName: c.firstName,
              lastName: c.lastName,
              contests: [
                for (final contest in c.contests)
                  LinkCandidateContestDto(
                    name: contest.name,
                    startDateTime: contest.startDateTime,
                    endDateTime: contest.endDateTime,
                    startDate: ContestTimeZones.localDate(
                      contest.timezone,
                      contest.startDateTime,
                    ),
                    endDate: ContestTimeZones.localDate(
                      contest.timezone,
                      contest.endDateTime,
                    ),
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
    final links = await service();
    final link = await links.confirmCandidate(
      profileId: await links.profileOfCandidate(
        candidateId: _idOrNotFound(id),
        accountId: principal.accountId,
      ),
      accountId: principal.accountId,
    );
    return answer((await _linkDtos(repository, [link])).single.toJson());
  });

  router.post('/account/link-candidates/<id>/decline', (
    Request request,
    String id,
  ) async {
    final principal = requirePrincipal(request);
    final links = await service();
    await links.declineCandidate(
      profileId: await links.profileOfCandidate(
        candidateId: _idOrNotFound(id),
        accountId: principal.accountId,
      ),
      accountId: principal.accountId,
    );
    return Response(204, headers: {'cache-control': 'no-store'});
  });

  router.post('/account/invitation-claims', (Request request) async {
    final principal = requirePrincipal(request);
    final links = await service();
    final address = clientAddressOf(
      request,
      trustedProxySecret: trustedProxySecret,
    );
    final wait = await limits.admit(address);
    if (wait != null) {
      return errorResponse(
        429,
        'rate_limited',
        'Too many attempts. Try again later.',
        requestId: requestIdOf(request),
      ).change(headers: {'retry-after': '${wait.inSeconds + 1}'});
    }
    final ResolveInvitationRequest body;
    try {
      body = await readJsonBody(request, ResolveInvitationRequest.fromJson);
    } on ArgumentError {
      await limits.recordFailure(address);
      rethrow;
    }
    try {
      final claimed = await links.claimInvitation(
        credential: body.credential.trim(),
        accountId: principal.accountId,
      );
      return await resolutionResponse(
        repository,
        request,
        claimed.session,
        now: now,
      );
    } on InvitationAccessError {
      await limits.recordFailure(address);
      rethrow;
    }
  });

  router.post('/account/participations/<id>/session', (
    Request request,
    String id,
  ) async {
    final principal = requirePrincipal(request);
    final session = await (await service()).openParticipation(
      participationId: _idOrNotFound(id),
      accountId: principal.accountId,
    );
    return resolutionResponse(repository, request, session, now: now);
  });

  router.get('/account/links', (Request request) async {
    final principal = requirePrincipal(request);
    final links = await (await service()).confirmedLinksFor(
      principal.accountId,
    );
    return answer(
      AccountLinksDto(links: await _linkDtos(repository, links)).toJson(),
    );
  });

  router.post('/account/links/<id>/end', (Request request, String id) async {
    final principal = requirePrincipal(request);
    final ended = await (await service()).end(
      linkId: _idOrNotFound(id),
      accountId: principal.accountId,
    );
    return answer((await _linkDtos(repository, [ended])).single.toJson());
  });
}

/// A path id that is not an id cannot be anyone's candidate or link: the same
/// answer as one that is not theirs.
Id _idOrNotFound(String text) {
  try {
    return Id.parse(text);
  } on FormatException {
    throw ParticipantLinkError.linkNotFound();
  } on ArgumentError {
    throw ParticipantLinkError.linkNotFound();
  }
}

/// The public results address of each contest in [contestIds] that is
/// published and public; the others have no entry. An unlisted or delisted
/// contest has none, so the list never links to a page the public cannot find.
Future<Map<Id, String>> _publicResultsUrls(
  Repository repository,
  String baseUrl,
  Set<Id> contestIds,
) async {
  final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
  final found = await Future.wait([
    for (final id in contestIds)
      repository.publicationIdentityRepository.findForContest(id),
  ]);
  return {
    for (final publication in found)
      if (publication != null &&
          publication.contestId != null &&
          publication.visibility == PublicationVisibility.public &&
          publication.publishedAt != null)
        publication.contestId!:
            '$base/results/contests/${publication.id.value}',
  };
}

/// The query parameter [name] as a whole number in [min]..[max], or
/// [fallback] when absent. Anything else is a 400.
int _pageNumber(
  Request request,
  String name, {
  required int fallback,
  required int min,
  int? max,
}) {
  final text = request.url.queryParameters[name];
  if (text == null) return fallback;
  final value = int.tryParse(text);
  if (value == null || value < min || (max != null && value > max)) {
    throw ArgumentError.value(
      text,
      name,
      'must be a whole number from $min'
      '${max == null ? '' : ' to $max'}',
    );
  }
  return value;
}

AccountHistoryEntryDto _historyDto(
  PastParticipation row,
  String? publicResultsUrl,
) {
  final contest = row.contest;
  return AccountHistoryEntryDto(
    participationId: row.participation.id,
    contestId: contest.id,
    contestName: contest.name,
    startDateTime: contest.startDateTime,
    endDateTime: contest.endDateTime,
    startDate: ContestTimeZones.localDate(
      contest.timezone,
      contest.startDateTime,
    ),
    endDate: ContestTimeZones.localDate(contest.timezone, contest.endDateTime),
    timezone: contest.timezone,
    host: contest.host,
    city: contest.city,
    state: contest.state,
    country: contest.country,
    publicResultsUrl: publicResultsUrl,
  );
}

AccountParticipationDto _participationDto(
  LinkedParticipation row,
  String? publicResultsUrl,
) {
  final contest = row.contest;
  return AccountParticipationDto(
    participationId: row.participationId,
    contestId: contest.id,
    contestName: contest.name,
    startDateTime: contest.startDateTime,
    endDateTime: contest.endDateTime,
    startDate: ContestTimeZones.localDate(
      contest.timezone,
      contest.startDateTime,
    ),
    endDate: ContestTimeZones.localDate(contest.timezone, contest.endDateTime),
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
    publicResultsUrl: publicResultsUrl,
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
