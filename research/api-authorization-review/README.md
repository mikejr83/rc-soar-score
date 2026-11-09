# API Authorization Review: Contest Ownership Gaps and Secondary Findings

Security review of the Soar Score API (`packages/soar_score_api_handlers` + the
services it calls) performed in October 2026. The question: can one signed-in
user read or modify another user's data? This document records what was
discovered and how it is fixed (§3).

## TL;DR

- **Any signed-in account can read and modify every contest.** The API authenticates every `/api/v1` request but never checks that the caller owns the contest named in the URL. `GET /contests` returns all contests in the database, and every contest-scoped route (scores, matrix, participations, teams, results, configuration, contest updates and lifecycle actions) acts for the caller regardless of ownership.
- **The sync layer and the publication layer already do this correctly.** Five existing sites throw `ForbiddenError('not_director', ...)`, which `error_mapping.dart` maps to 403. The fix is to bring the plain REST routes in line with that established convention.
- **Fix is handler-level only.** No service signature changes are needed; the services are shared with the sync and offline paths, where ownership is already enforced at a different layer.
- Secondary findings (body size cap, client-chosen ids, no-auth E2E server) are real but lower-severity and are tracked separately, see §4.

## 1. Scope and method

- **In scope:** the hosted-server authorization of every `/api/v1` route, and the embedded offline instance's interaction with the fix.
- **Out of scope:** transport and deployment (TLS, host headers, CDN), the public site data flow (`/public/*` is a deliberate, read-only publication), and the self-scoring invitation design (participants have no account until the guest-session endpoints land — see §5).
- **Method:** route-by-route audit of `packages/soar_score_api_handlers/lib/handlers/` following each route into the `soar_score_core` services it calls, checking every place an ownership decision could be made. File:line references below are current as of this writing.

## 2. The gap

### 2.1 There is no ownership check on the contest-scoped routes

The pipeline for every request is CORS → request id → logging → error mapping
(`packages/soar_score_api_handlers/lib/middleware/middleware.dart:19`), with
the pluggable auth middleware supplying the request's `Principal`
(`handler.dart`, `auth/principal.dart`). Nothing after the `Principal` is set
compares it to the contest it addresses.

The concrete holes:

- **The contest list is unscoped.** `GET /contests` calls
  `ContestsService.getContests()`, which is `contestRepository.getAll()`
  (`packages/soar_score_core/lib/services/contests_service.dart:38`). Every
  account sees every contest, including private and pending ones — and can
  open each one by id from there.
- **The single-contest route is existence-only.** `ContestsService.getContest`
  goes through `_require(id)`, which throws `EntityNotFoundError` when the id
  is unknown and nothing about who is asking
  (`contests_service.dart:46`, `:190`).
- **Every mutation accepts any caller.** `PUT /contests/{id}`,
  `POST /contests/{id}/actions` (lifecycle: lock, complete), score entry,
  matrix draws/moves/redraws, participation adds/edits/removals, team and
  membership changes, configuration revisions, and result recalculation all
  run for whatever `Principal` supplied the valid token.

### 2.2 Route inventory (29 contest-scoped routes in 7 files)

| File                           | Routes                                                                                                                                                |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `contests_handlers.dart`       | `GET /contests/{id}`, `PUT /contests/{id}`, `POST /contests/{id}/actions`, `GET /contests/{id}/audit-events`                                          |
| `scores_handlers.dart`         | `GET .../scores`, `GET .../assignments/{assignmentId}/scores/history`, `POST .../assignments/{assignmentId}/scores`                                   |
| `matrix_handlers.dart`         | `GET .../matrix`, `POST .../matrix/draws`, `POST .../matrix/assignments/{assignmentId}/moves`, `POST .../matrix/late-adds`, `POST .../matrix/redraws` |
| `participations_handlers.dart` | get, post, put, delete                                                                                                                                |
| `teams_handlers.dart`          | get, post, put, delete on `teams`; get, post, delete on `team-memberships`                                                                            |
| `results_handlers.dart`        | `GET .../results`, `GET .../results/rounds/{ordinal}`, `POST .../results/recalculation`                                                               |
| `configuration_handlers.dart`  | get, `revisions`, post                                                                                                                                |

Verified against the `router.*` registrations in each file. `POST /contests`
(create) needs no guard: the creator becomes the owner.

### 2.3 What is already protected

These routes look contest-scoped but are correctly gated, so they are
**excluded** from the fix:

- **Publication** (`publication_handlers.dart`, 2 routes): the service enforces
  `_requireDirector`
  (`packages/soar_score_core/lib/services/publication/publication_service.dart:362`,
  applied at `read` :289 and visibility changes :317).
- **Sync** (`sync_handlers.dart`, incl. `POST /contests/{id}/activations`):
  `SyncAcceptorService._requireScopeAccess` (:309),
  `MutationProcessor._ownershipProblem` (:613), `ConflictResolver.find` (:54)
  and `InstallationSyncService.activate` (:110) all check
  `owner_account_id` against the acting account and fail with
  `ForbiddenError('not_director', ...)`.
- **Owner-scoped row routes** — participants, roles, landing tables: every
  service call takes an `ownerAccountId` parameter and `_require*` compares it
  (e.g. `participations_service.dart:200`, `roles_service.dart:140`,
  `participants_service.dart:123`).
- **Account and preference routes** act only on the caller's own account.
- **JWT and CORS** are sound: RS256 checked against the tenant JWKS with
  `exp`, `iss`, `aud`; `aud` is fixed to the API identifier; CORS origins are
  configured, not echoed.

The `not_director` pattern is the house convention. The fix mirrors it rather
than inventing a new one.

## 3. The fix design

Decided scope: **authorization fix only**, handler-level.

### 3.1 Helper

New file `packages/soar_score_api_handlers/lib/handlers/contest_authorization.dart`:

```dart
Future<void> requireContestDirector(
  Request request,
  Repository repository,
  Id contestId,
) async {
  final principal = requirePrincipal(request);
  final contest = await repository.contestRepository.findById(contestId);
  if (contest == null) {
    throw EntityNotFoundError(entityType: 'Contest', entityId: contestId);
  }
  if (contest.ownerAccountId != principal.accountId) {
    throw ForbiddenError('not_director', 'only the director of the contest may');
  }
}
```

- Existence before ownership, so unknown ids stay 404 (no change in which ids
  "exist"); a foreign caller gets 403 on a real one. Same ordering as
  `PublicationService._requireDirector`.
- `ForbiddenError` → 403 and `EntityNotFoundError` → 404 already exist in
  `error_mapping.dart` (:82–85); the client already renders 403 as
  "not allowed" via `ApiFailure` / `PageStateView`.
- The guard runs before `readJsonBody`: an unauthorized call drops its body
  without parsing it.

### 3.2 Scoped contest list

`GET /contests` filters the existing `getAll()` result in the handler:

```dart
if (contest.ownerAccountId == principal.accountId ||
    principal.alsoVisibleOwners.contains(contest.ownerAccountId))
```

- On the hosted server `alsoVisibleOwners` is always empty (the JWT middleware
  never populates it), so callers see only what they own — no new exposure.
- No new `ContestRepository` method: adding one would ripple into the
  `Repository` interface and the drift, stub and e2e implementations for a
  single consumer.

### 3.3 Embedded offline instance

`apps/soar_score_contest/lib/server/owner_scoped_principal.dart` already
re-scopes the principal to the contest's owner for `/contests/{id}/...` routes
and sets `alsoVisibleOwners` for the participants/roles/landing-table lists,
so the guard passes there unchanged. Two interactions:

- The embedded **contest list** must keep showing contests imported for
  inspection (owned by an inspection owner, not the acting account): extend
  `listsAcrossOwners` to cover `GET /contests` so the filter's
  `alsoVisibleOwners` clause does its job. No visible change in the hosted
  case.
- The re-scoping interaction with the new guard is locked in by a test
  rather than assumed.

Compatibility check: the embedded app's home page and the wizard's copy-source
list both call `client.contests()`, so both pick up imported contests through
the same mechanism.

## 4. Secondary findings (separate tickets)

Real issues, lower severity, deliberately not part of the authorization fix:

1. **No request body size limit.** `readJsonBody`
   (`packages/soar_score_api_handlers/lib/handlers/request_body.dart:12`)
   decodes the whole body with no cap; a large JSON payload is parsed
   in memory. Bounded parsing or a size cap is needed.
2. **Client-chosen entity ids.** `POST /contests` and several other routes
   accept an `id` from the body (`NewContest.id`), so a caller can pre-claim or
   overwrite ids it knows, within its own ownership. Low severity now that
   ownership is enforced, but client-chosen ids remain a weak convention.
3. **No-auth E2E server.** `apps/soar_score_server/tool/e2e_server.dart` has no
   token checks by design (local web E2E only, "must never be deployed").
   Worth a deployment guard so it is not mistaken for a real server.
4. **Import endpoint.** `POST /imports/gliderscore` reads a file path the
   caller supplies; it is only reachable on the native server today, but a
   follow-up should state that restriction explicitly.

## 5. Interaction with participant (self-scoring) access

Confirmed against
`plan/ui/participant-scoring/participant-scoring.md`: participants have **no
account**. They arrive through `/invitations/{credential}`; the API issues a
**guest session** ("the session identifies the participant link and contest,
so later requests do not need the credential") and the credential is removed
from the address bar after acceptance.

Consequence: participant score entry will be a future, invitation-scoped
endpoint with its own authentication layer — **not** the director route.
Gating `POST /contests/{id}/assignments/{assignmentId}/scores` to the
director in this fix is therefore correct and needs no exception clause; the
guest-session endpoints are a separate work item.

## 6. Risks and edge cases considered

- **Clients only navigate to their own contests** in the UI, and sync scopes
  are already owner-checked — no client-visible change expected; a 403
  surfaces as the standard "not allowed" state.
- **The self-scoring app** reads publications only (via `/public/*`); it does
  not call the director routes.
- **Two handler stacks over one repository** in tests share stub state — each
  test's arrangement must stay self-contained.
- The public site (`/public/*`) is intentionally untouched.

## 7. Verification plan (summary)

- Handler tests (`packages/soar_score_api_handlers/test`): two principals over
  one shared stub repository — owner gets 200, foreign principal gets 403
  with code `not_director`, unknown id gets 404; list scoping incl.
  `alsoVisibleOwners` visibility.
- Slice tests (`apps/soar_score_server/test/api_slice/`): a second account
  against the same real database (SQLite + Postgres profiles) — create as A,
  denied as B. This is the cross-tenant regression net.
- E2E (`scripts/e2e-contest.ps1`, incl. `-d web`): the embedded flows, including the
  imported-for-inspection contest list, must pass unchanged.
- Gate: `melos analyze` clean, `melos test` green.
