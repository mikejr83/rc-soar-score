import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart'
    show
        Account,
        AccountKind,
        Authority,
        Id,
        InvitationService,
        MutationMetadata,
        ParticipantLinkError,
        ParticipantLinkService,
        ParticipantProfile;
import 'package:soar_score_data/soar_score_data.dart' show Repository;

/// The bearer token that makes a request of the E2E server act as the pilot
/// account instead of the director. There is no token check: the word is the
/// whole credential, and the server is never deployed.
const e2ePilotToken = 'e2e-pilot';

/// The verified email of the seeded pilot account, which a profile must carry
/// to be offered to it as an "Is this you?" match.
const e2ePilotEmail = 'penny.pilot@example.com';

/// Creates the pilot account the self-scoring app's signed-in journeys act as:
/// a registered, active account with a verified email and no contests.
Future<Id> seedE2ePilotAccount(Repository repository) async {
  final id = Id.create();
  final now = DateTime.now().toUtc();
  await repository.accountRepository.save(
    Account(
      id: id,
      firstName: 'Penny',
      lastName: 'Pilot',
      email: e2ePilotEmail,
      emailVerified: true,
      kind: AccountKind.registered,
      createdAt: now,
      updatedAt: now,
    ),
  );
  return id;
}

/// The auth layer of the E2E server: every request acts as [director], except
/// one that sends `Authorization: Bearer e2e-pilot`, which acts as [pilot].
///
/// The director's calls (a journey's setup) carry no header, so they are
/// unchanged. The signed-in self-scoring app sends the pilot token the way it
/// sends an Auth0 access token to the hosted server.
Handler Function(Handler) e2ePrincipal({
  required Id director,
  required Id pilot,
}) {
  final asDirector = fixedPrincipal(Principal(accountId: director));
  final asPilot = fixedPrincipal(Principal(accountId: pilot));
  return (inner) {
    final director = asDirector(inner);
    final pilot = asPilot(inner);
    return (request) =>
        request.headers['authorization'] == 'Bearer $e2ePilotToken'
        ? pilot(request)
        : director(request);
  };
}

/// `POST /__e2e/pilot-account-link`: puts the seeded pilot account in front of
/// a participation of a contest the journey created, in one of two states.
///
/// The body is `{"participation_id", "state"}`, `state` being:
///
/// - `candidate`: the participation's profile gets the pilot's verified email
///   (as the director typing the pilot's address would), so the account's
///   "Is this you?" list offers it. The pilot account is not linked.
/// - `confirmed`: the same, and the match is then confirmed through
///   [ParticipantLinkService.confirmCandidate], exactly as the pilot's tap on
///   "Yes, that's me" does (which also claims the entries of the profile's
///   guests). The contest then appears in `GET /account/participations`.
///
/// Both need the director to have issued an invitation of the participation
/// that still opens (a journey does this through the API, as it does for a
/// guest); without one the participation is no match and the answer is 409
/// `link_not_found`, as does asking for `candidate` once the profile is linked. Repeating a request is otherwise a no-op. The answer is
/// `{"account_id", "profile_id"}`: the pilot account and the director's
/// profile, never a credential.
///
/// Test-only, like the rest of the E2E server.
Middleware e2ePilotAccountLink(
  Repository repository,
  InvitationService invitations, {
  required Id pilot,
}) {
  final links = ParticipantLinkService(repository, invitations);
  return (inner) => (request) async {
    if (request.method != 'POST' ||
        request.url.path != '__e2e/pilot-account-link') {
      return inner(request);
    }
    String bodyText;
    Map<String, dynamic> body;
    try {
      bodyText = await request.readAsString();
      body = jsonDecode(bodyText) as Map<String, dynamic>;
    } on FormatException {
      return Response.badRequest(body: 'Invalid JSON body.');
    }
    final state = body['state'];
    if (state != 'candidate' && state != 'confirmed') {
      return Response.badRequest(body: 'state is candidate or confirmed.');
    }
    final participationIdRaw = body['participation_id'];
    if (participationIdRaw == null) {
      return Response.badRequest(body: 'participation_id is required.');
    }
    final participation = await repository.contestParticipationRepository
        .findById(Id.parse(participationIdRaw as String));
    final profile = participation == null
        ? null
        : await repository.participantProfileRepository.findById(
            participation.participantProfileId,
          );
    if (profile == null) {
      return Response.notFound('No such participation.');
    }
    final account = (await repository.accountRepository.findById(pilot))!;
    if (profile.email != account.email) {
      await repository.participantProfileRepository.save(
        ParticipantProfile(
          id: profile.id,
          ownerAccountId: profile.ownerAccountId,
          firstName: profile.firstName,
          lastName: profile.lastName,
          club: profile.club,
          faiNumber: profile.faiNumber,
          nationalOrgId: profile.nationalOrgId,
          city: profile.city,
          state: profile.state,
          country: profile.country,
          email: account.email,
          createdAt: profile.createdAt,
          updatedAt: DateTime.now().toUtc(),
          revision: profile.revision,
        ),
        metadata: MutationMetadata(
          clientMutationId: 'e2e-pilot-email-${Id.create().value}',
          authority: Authority.director,
          clientTime: DateTime.now().toUtc(),
          actorId: profile.ownerAccountId,
        ),
      );
    }
    if (state == 'confirmed') {
      try {
        await links.confirmCandidate(profileId: profile.id, accountId: pilot);
      } on ParticipantLinkError catch (error) {
        // Answered here so the browser can read it (an escaped error is a
        // 500 without CORS headers).
        return Response(409, body: '${error.code}: ${error.message}');
      }
    } else if ((await links.candidatesFor(pilot))
        .every((c) => c.profileId != profile.id)) {
      return Response(
        409,
        body: 'link_not_found: the participation has no invitation that opens.',
      );
    }
    return Response.ok(
      jsonEncode({'account_id': pilot.value, 'profile_id': profile.id.value}),
      headers: {'content-type': 'application/json'},
    );
  };
}
