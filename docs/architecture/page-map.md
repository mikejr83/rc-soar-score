# Application Page Map

This document maps user-facing page names to routes and source files across the Soar Score applications. Use it to locate implementation entry points. For detailed contest-app behavior and component relationships, see `contest-app-architecture.md`. For score lifecycle invariants, see `scoring-lifecycle.md`.

When someone refers to a page by name, use this table. Paths below are all in `apps/`; routes are defined in each app's `lib/router.dart` (go_router), and the contest app's route constants and path helpers live at the top of that file.

## Contest app (`soar_score_contest`)

The landing page has no app shell. Every other page sits in the shell (`lib/widgets/contest_shell.dart`), whose rail (`shell_rail.dart`) shows one of two destination sets chosen in `shell_destinations.dart`: system scope (outside a selected contest) and contest scope (any route below `/contest-administration/contests/:contestId`, except the wizard).

| Name people use                                                      | Route                                                  | Source (`lib/`)                                                         |
| -------------------------------------------------------------------- | ------------------------------------------------------ | ----------------------------------------------------------------------- |
| Landing page (sign in / "Continue offline"), no shell                | `/contest-administration`                              | `pages/landing_page.dart`                                               |
| Main page, contests page, contest list ("Contests" rail entry)       | `/contest-administration/home`                         | `pages/home_page.dart`, `widgets/contest_list.dart`                     |
| New contest wizard (rail "Create contest" button)                    | `/contest-administration/contests/new`                 | `pages/new_contest_wizard_page.dart`, `widgets/new_contest/`            |
| Workspace (contest scope, "Workspace" rail entry)                    | `/contest-administration/contests/:id/workspace`       | `pages/contest_workspace_page.dart`                                     |
| Contest configuration page ("Configuration" rail entry)              | `/contest-administration/contests/:id/configuration`   | `pages/contest_configuration_page.dart`, `widgets/configuration/`       |
| Matrix page, draw ("Matrix" rail entry)                              | `/contest-administration/contests/:id/matrix`          | `pages/matrix_page.dart`, `widgets/matrix/`                             |
| Contest participants page (contest scope, "Participants" rail entry) | `/contest-administration/contests/:id/participants`    | `pages/contest/participants_page.dart`, `widgets/contest_participants/` |
| Contest scoring page (contest scope, "Scoring" rail entry)           | `/contest-administration/contests/:id/scoring`         | `pages/contest/scoring_page.dart`, `widgets/scoring/`                   |
| Contest reports page (contest scope, "Reports" rail entry)           | `/contest-administration/contests/:id/reports`         | `pages/contest/reports_page.dart`                                       |
| Report viewer (outside the shell; opens from a report card)          | `/contest-administration/contests/:id/reports/:report` | `pages/contest/report_viewer_page.dart`, `widgets/reports/viewer/`      |
| Contest sync page (contest scope, "Sync" rail entry, native only)    | `/contest-administration/contests/:id/sync`            | `pages/contest/sync_page.dart`, `widgets/sync/`                         |
| Participants manager ("Participants" rail entry)                     | `/contest-administration/participants`                 | `pages/participants_page.dart`                                          |
| Participant editor (new / edit)                                      | `/contest-administration/participants/new`, `/:id`     | `pages/participant_editor_page.dart`, `widgets/participant_editor/`     |
| Role manager ("Roles" rail entry)                                    | `/contest-administration/roles`                        | `pages/roles_page.dart`, `widgets/roles/`                               |
| Landings manager ("Landings" rail entry)                             | `/contest-administration/landings`                     | `pages/landings_page.dart`, `widgets/landings/`                         |
| Account sync (the sync status outside a contest; native only)        | `/contest-administration/account-sync`                 | `pages/contest/sync_page.dart` (`AccountSyncPage`), `widgets/sync/`     |
| Settings page (account control at the bottom of the rail)            | `/contest-administration/settings`                     | `pages/settings_page.dart`, `widgets/settings/`                         |
| Landing table editor (new / copy)                                    | `/contest-administration/landings/new`                 | `pages/landing_editor_page.dart`                                        |
| Startup failure page (not a route)                                   | none                                                   | `pages/bootstrap_failure_page.dart`                                     |

## Public site (`soar_score_web`)

A Next.js app (App Router, TypeScript; ADR 0005), not Flutter: marketing and information, docs and help, support, and the published results. Routes are files under `src/app/`; every route renders inside the root layout's header and footer (`src/components/site-header.tsx`, `site-footer.tsx`); unknown routes show `src/app/not-found.tsx`. `next.config.ts` redirects `/results` to `/results/contests` and `/help` to `/docs`. Run with `npm run dev` in `apps/soar_score_web` (see its `AGENTS.md`).

| Name people use                                                       | Route                                                                                 | Source (`src/app/`)                                                          |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Site home, landing, homepage                                          | `/`                                                                                   | `page.tsx`, sections in `src/components/home/`                               |
| Contests, contest search (`?name=&venue=&from=&to=` filters)          | `/results/contests`                                                                   | `results/contests/page.tsx`, `src/components/results/`                       |
| Not found (not a route)                                               | none                                                                                  | `not-found.tsx`                                                              |
| Contest results, overall individual results (as of a round)           | `/results/contests/:contestId`, `/results/contests/:contestId/rounds/:roundNumber`    | `results/contests/[contestId]/page.tsx`, `.../rounds/[roundNumber]/page.tsx` |
| Team scores, team results (as of a round)                             | `/results/contests/:contestId/teams/results`, `.../teams/results/rounds/:roundNumber` | `results/contests/[contestId]/teams/results/...`                             |
| Flight group scores, groups of a round (`?pilot=` scrolls to a pilot) | `/results/contests/:contestId/rounds/:roundNumber/flight-groups`                      | `results/contests/[contestId]/rounds/[roundNumber]/flight-groups/page.tsx`   |
| Contest not found (unknown or delisted, shown in place)               | none                                                                                  | `src/components/results/contest-not-found.tsx`                               |
| Contest not visible (pending or private, re-checks every 15 minutes)  | none                                                                                  | `src/components/results/contest-not-visible.tsx`                             |

The contest views share `results/contests/[contestId]/layout.tsx`, a client provider that loads the publication once per contest, so moving between views or rounds keeps the loaded contest. Parsed models live in `src/lib/results/` (`published-contest.ts`, `contest-summary.ts`, `contest-filters.ts`, `paths.ts`); components never read the raw projection maps. The flight-group table reads the provisional `raw_components` (#456) and `reflight` (#457) score keys and hides those columns until the server emits them.

Documentation, help and support (spec: `plan/ui/public-site/docs-help.md`, `support.md`) share `docs/layout.tsx` (sidebar navigation from `src/components/docs/topics.ts`). Content is draft copy pending #165 and carries a note saying so.

| Name people use                                    | Route                                       | Source (`src/app/`)                                    |
| -------------------------------------------------- | ------------------------------------------- | ------------------------------------------------------ |
| Docs landing, help landing                         | `/docs` (`/help` redirects here)            | `docs/page.tsx`                                        |
| Contest Director Getting Started, competition help | `/docs/competitions`                        | `docs/competitions/page.tsx`                           |
| Help Me Enter My Score, participant scoring help   | `/docs/participant-scoring`                 | `docs/participant-scoring/page.tsx`                    |
| F5J score entry quick reference                    | `/docs/participant-scoring/disciplines/f5j` | `docs/participant-scoring/disciplines/f5j/page.tsx`    |
| I Need An Account?, user account help              | `/docs/user-accounts`                       | `docs/user-accounts/page.tsx`                          |
| Finding Contests and Results, public contests help | `/docs/contests-and-scores`                 | `docs/contests-and-scores/page.tsx`                    |
| Docs not found (any unknown route under `/docs`)   | `/docs/not-found`                           | `docs/not-found/page.tsx` (`docs/[...rest]` redirects) |
| Support, request support                           | `/support`                                  | `support/page.tsx`, `src/components/support/`          |

## Self-scoring app (`soar_score_self_score`)

| Name people use                                           | Route                                                        | Source (`lib/`)                  |
| --------------------------------------------------------- | ------------------------------------------------------------ | -------------------------------- |
| Landing page (Sign in / Sign up)                          | `/`                                                          | `pages/home_page.dart`           |
| Contests list, "Is this you?"                             | `/contests`                                                  | `pages/contests_page.dart`       |
| Account (linked profiles, past contests, directory entry) | `/account`                                                   | `pages/account_page.dart`        |
| Directory details (what directors may find)               | `/details`                                                   | `pages/details_page.dart`        |
| Application info (licences, Privacy Policy, Terms)        | `/app-info`                                                  | `pages/app_info_page.dart`       |
| Invitation link (guest session)                           | `/invitations/:credential`                                   | `pages/invitation_page.dart`     |
| Contest entry (guest: pilot overview; else team overview) | `/contests/:contestId`                                       | `router.dart`                    |
| Team overview (helper view, team standings)               | `/contests/:contestId/team`                                  | `pages/team_page.dart`           |
| Pilot overview (round cards, retire)                      | `/contests/:contestId/pilots/:pilotId`                       | `pages/pilot_overview_page.dart` |
| Score entry (F5J form, landing sheet/combobox)            | `/contests/:contestId/pilots/:pilotId/rounds/:roundId`       | `pages/score_entry_page.dart`    |
| Group results (not in the spec's route table)             | `/contests/:contestId/pilots/:pilotId/rounds/:roundId/group` | `pages/group_results_page.dart`  |
| Results (latest, or `?round=N` as of a round)             | `/contests/:contestId/results`                               | `pages/results_page.dart`        |

Routes follow `plan/ui/participant-scoring/participant-scoring.md`. The invitation handler checks the link, then Continue as guest stores the guest session (`session/`, browser local storage) and replaces the address with the pilot overview; Sign in and Create account are inert until #545/#546. The app uses path URLs (not `#/`), so `apps/soar_score_self_score/wrangler.jsonc` turns on the SPA fallback and the page sends no referrer. Contest entry sends a guest to their pilot overview and everyone else to the team overview until accounts and helpers exist. On the pilot overview, View opens the group results for the round until the read-only score view exists; Copy invitation link and Retire are not connected to the API. The path helpers are at the top of `router.dart`.

Pages read through `SelfScoreRepository` (`data/self_score_repository.dart`, provided by `SelfScoreScope`) and load with `LoadableScaffold` (loading, error and Retry states). `main.dart` provides `ApiSelfScoreRepository` (`data/api_self_score_repository.dart`, over the `/api/v1/self-scoring/*` calls on `ApiClient`; the guest session token is the client's bearer token). `SampleSelfScoreRepository`, backed by `data/sample_data.dart`, stays for tests and design review (`--dart-define=SOAR_SCORE_SAMPLE_DATA=true`). Score entry submits through `SelfScoreRepository.submitScore` with a client mutation id; the form keeps a draft in browser storage (`session/score_draft_store.dart`) and sends a queued score again with the same id. The contests list and team overview show a coming-soon message on the API repository, and the results page hides the Teams toggle when there are no team standings. The landing field picks its control by table size (`widgets/landing_control.dart`: sheet up to 20 results, autocomplete above); see `plan/ui/participant-scoring/landing-control-decision.md`.

## Server (`soar_score_server`)

The server has no pages. Its HTTP routes (`/roles`, `/participants`, `/landing-tables`, `/health`, public `/publications`, and so on) are defined in `packages/soar_score_api_handlers/lib/handlers/`.

Keep this section current: a PR that adds, renames or moves a page route updates the table.
