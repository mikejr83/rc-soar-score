# Contest Controls — Implementation Analysis

Analysis of the "Contest controls (state actions)" section (Section 4) of the Contest Workspace design brief, mapped against the current Soar Score codebase to determine what can be implemented today and which outstanding work gates the full set of controls.

Source files examined:

- `plan/ui/contest-administration/briefs/workspace.md` (the design brief, Section 4 "Contest controls")
- `plan/ui/contest-administration/contest-workspace.md` (the page requirement)
- `plan/architecture-requirements/contest-state-and-transitions.md` (the state model and transitions)
- `packages/soar_score_core/lib/enums/contest_action.dart` (`ContestAction`)
- `packages/soar_score_core/lib/models/contest.dart` (`Contest`)
- `packages/soar_score_api/lib/client/api_client.dart` (client surface)
- `packages/soar_score_api/lib/dto/contest_action_request.dart`, `publish_contest_request.dart`, `set_visibility_request.dart`
- `packages/soar_score_api/lib/errors/api_http_error.dart` (the 409 conflict signal)
- `packages/soar_score_api_handlers/lib/handlers/contests_handlers.dart` (`handleApplyContestAction`)
- `packages/soar_score_api_handlers/lib/handlers/publication_handlers.dart` (`handlePublishContest`, `handleSetPublicationVisibility`)
- `packages/soar_score_api_handlers/lib/handler.dart` (`createApiHandler`, the `publishingEnabled` gate)
- `apps/soar_score_contest/lib/api_client_provider.dart` (the `ApiClient` seam for widgets)
- `apps/soar_score_contest/lib/services/configuration/configuration_data.dart`, `matrix/matrix_page_data.dart` (the loader-service convention)
- `apps/soar_score_contest/lib/services/connectivity/app_connectivity.dart` (`AppConnectivity`, the offline signal)
- `apps/soar_score_contest/lib/app_mode_provider.dart` (`AppModeNotifier`, offline mode)
- `apps/soar_score_contest/lib/pages/contest_workspace_page.dart` (current workspace page)
- GitHub issue #250 (open, checked 10 Oct 2026)

## What the design specifies

**Contest controls** are the controls that change the contest's state. Each shows its **current value**, the **action**, and, when disabled, the **reason beside it**. The brief asks for one shared pattern for all of them.

The controls:

1. **Participant scoring** — Open / Close. Closing stops pilots and helpers from entering scores; the director can still enter them.
2. **Administration lock** — Lock / Unlock, with a confirmation that lists what becomes blocked (configuration, participants, matrix changes).
3. **Complete contest** — closes the contest (a director decision, suggested once it looks finished).
4. **Publish / delist** — publishing copies the contest to the public site; delisting removes it after an approved request.
5. **Visibility** — Unlisted / Public, only once published.
6. **Hide results** — overall results Shown / Hidden (through round N), expiring 24 hours after being turned on.
7. **Local archive** — Archived / Not archived; local to this installation, never deletes data.

Interaction model (from the brief):

- **Destructive / terminal** actions (lock, complete, publish, delist) use **confirmation dialogs**.
- **Immediate** actions (open/close scoring, hide results) take effect directly with a snackbar and undo where safe.
- A **stale revision or a rejected transition** leaves the page unchanged and shows why, with retry or refresh.
- **Offline:** server-only actions (publish, visibility, delisting) are shown disabled with "Needs a connection" when offline; local actions still work.

## Data required, and where it comes from

All **current values** for the controls are already present on the `Contest` model returned by the `ApiClient`'s contest read. No new read endpoint is needed.

| Control                       | Current value on `Contest` | Source                                                                      |
| ----------------------------- | -------------------------- | --------------------------------------------------------------------------- |
| Participant scoring           | `scoringOpen`              | `Contest.scoringOpen`                                                       |
| Administration lock           | `adminLocked`              | `Contest.adminLocked`                                                       |
| Complete contest              | `lifecycle`                | `Contest.lifecycle`                                                         |
| Publish / visibility / delist | `publication`              | `Contest.publication` (`PublicationInfo`: `clientMutationId`, `visibility`) |
| Local archive                 | (none today)               | not present on `Contest`                                                    |

The **mutations** all go through the existing `ApiClient` surface:

| Control action               | `ApiClient` method         | Request DTO             | `ContestAction` value | Server handler                   |
| ---------------------------- | -------------------------- | ----------------------- | --------------------- | -------------------------------- |
| Complete contest             | `applyContestAction`       | `ContestActionRequest`  | `complete`            | `handleApplyContestAction`       |
| Open scoring                 | `applyContestAction`       | `ContestActionRequest`  | `openScoring`         | `handleApplyContestAction`       |
| Close scoring                | `applyContestAction`       | `ContestActionRequest`  | `closeScoring`        | `handleApplyContestAction`       |
| Lock admin                   | `applyContestAction`       | `ContestActionRequest`  | `lock`                | `handleApplyContestAction`       |
| Unlock admin                 | `applyContestAction`       | `ContestActionRequest`  | `unlock`              | `handleApplyContestAction`       |
| Publish / delist             | `publishContest`           | `PublishContestRequest` | —                     | `handlePublishContest`           |
| Visibility (Unlisted↔Public) | `setPublicationVisibility` | `SetVisibilityRequest`  | —                     | `handleSetPublicationVisibility` |

`ContestActionRequest` carries `action` plus `baseRevision` (the contest revision the caller read; a different stored revision is answered with 409). `PublishContestRequest` carries `clientMutationId` (idempotency) plus `sourceContestRevision` (a contest that has moved on is answered with 409 `stale_source_revision`). `SetVisibilityRequest` carries the visibility as a string (`Unlisted` / `Public`; anything else is 400).

So the controls have **current-value data and mutation endpoints for five of the control groups**, with zero new reads and zero new endpoints for those five.

## The feasibility gaps

### 1. Hide-results has no backend

> Update (#237): `ContestAction` now also has `hideResults` and `showResults`, and `Contest` carries `resultsHiddenThroughRound` and `resultsHiddenAt`. The paragraph below describes the state before that change.

`ContestAction` contains only `complete`, `openScoring`, `closeScoring`, `lock`, `unlock`. There is **no** `hideScores` / `unhideScores` action, **no** "overall results Shown / Hidden through round N (24-hour expiry)" field on `Contest`, and **no** server handler for it. The brief describes hide-results as a control with a countdown, but the data model and API have no such state.

Options:

- **Out of scope for this ticket** (most likely) and tracked as a follow-up issue that needs a new `Contest` field, a new `ContestAction` value, a server transition, and a client method.
- **Rendered as a stubbed/disabled control** with a "not yet available" reason, per the brief's general "stub until the data exists" instruction.

Recommendation: implement the five backed control groups now and represent hide-results as a disabled stub with an explicit reason, so the ticket stays shippable without inventing an unrequested API surface.

### 2. Archive has no `ApiClient` method

Like hide-results, **archive/unarchive has no `ContestAction` value and no `ApiClient` method** in the current client. It would be a stub until the backend adds it.

### 3. Publish/visibility depend on `publishingEnabled`

`createApiHandler(..., publishingEnabled: ...)` gates the publication routes. There is **no reference to `publishingEnabled` in the contest app** (`lib/` or `test/`), which means the app's embedded server likely boots with it **defaulting to false** — so `publishContest` returns 409 `publishing_not_available` and visibility/delist 404 until the flag is wired on. This is a one-line bootstrap change (pass `publishingEnabled: true` in `native_bootstrap.dart` / `web_bootstrap.dart`) but it must be verified before the publish controls are treated as live.

Note on offline semantics: the brief's "offline: publish/visibility/delist disabled" rule is about **remote** reachability. The embedded loopback server is reachable offline, so these controls work offline once the flag is on; the "Needs a connection" disabling applies when running against a **remote** server that is unreachable.

## Architecture: no new service/repository layer

The contest app has **no repository or service layer that wraps `ApiClient` for mutations**. The established pattern is:

- `lib/api_client_provider.dart` — an `InheritedWidget` exposing the app's single `ApiClient` to the tree.
- `lib/services/<domain>/*_data.dart` — pure static loader classes (e.g. `ConfigurationData.load`, `MatrixPageData.load`).
- Pages take `ApiClient client` as a constructor parameter and call it directly.

So **Contest Controls should follow the same pattern**: a pure static helper for the _control decisions_ (which control is shown, enabled, and its disabled reason — derived from the `Contest` state), with the page invoking `ApiClient` directly. Do **not** invent a `ContestService` / `ContestRepository` — that would break the convention.

The offline signal is already available: `appConnectivityOf(context)` (`AppConnectivity.apiStatus`) for remote-API reachability, and `isOfflineModeOf(context)` (`AppModeNotifier`) for the user-chosen offline mode.

## Interaction model (per the brief)

| Control                      | Interaction                                                                                                         | Rationale                             |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| Lock admin                   | **Confirmation dialog** (lists what becomes blocked: configuration, participants, matrix)                           | Destructive, blocks other work        |
| Complete contest             | **Confirmation dialog** (with a "missing scores" group when applicable — reuses the Progress derivations, per #345) | Terminal lifecycle transition         |
| Publish                      | **Confirmation dialog**                                                                                             | Copies the contest to the public site |
| Delist                       | **Confirmation dialog**                                                                                             | Removes from public site              |
| Visibility (Unlisted↔Public) | Immediate + snackbar                                                                                                | Small reversible toggle               |
| Open scoring                 | Immediate + snackbar                                                                                                | Director can reopen                   |
| Close scoring                | Immediate + snackbar + **Undo**                                                                                     | Safe to undo (reopen)                 |
| Unlock admin                 | Immediate + snackbar                                                                                                | Safe to re-lock                       |
| Hide results (stub)          | n/a — disabled stub                                                                                                 | No backend                            |

**Shared state machine per control** (drives the control's render): `idle` → `busy` (single-flight; repeated taps ignored) → `success` (snackbar; refresh the `Contest`) or `failure`. `ApiHttpError` with status 409 is the conflict signal ("Someone else changed this contest. Refresh to see the current state." with retry/refresh); `ApiNetworkError` → "Needs a connection".

## Proposed widget/file structure (all in `apps/soar_score_contest/lib/`)

Follow the existing `widgets/<domain>/` convention and the small-file rule:

```
widgets/contest_controls/
  contest_controls.dart          # section container: builds the list of controls
                                 # for the current Contest, passes callbacks
  contest_control_row.dart       # THE shared pattern: one control row
                                 # (label, current-value chip, action button,
                                 #  disabled reason, busy spinner, Semantics)
  contest_control_spec.dart      # pure: ContestControlSpec -> Contest mapping
                                 # (which controls, current value label, action,
                                 #  enabled?, disabled reason, needs server?,
                                 #  confirmation copy). Fully unit-testable.
  confirmations.dart             # the 4 dialogs (lock, complete, publish, delist)
  contest_control_actions.dart   # pure static: the API invocations + result
                                 # handling (wraps client.applyContestAction /
                                 # publishContest / setPublicationVisibility,
                                 # maps 409 -> Conflict, network -> Offline)
```

`contest_workspace_page.dart` (currently a placeholder `WorkspaceBody` card) gains:

- The `ContestControls` section, fed by the `Contest` the page already loads.
- A `ChangeNotifier`-backed or per-control local `busy` state so a control is busy without blocking others.
- The offline signal via `appConnectivityOf(context)` + `isOfflineModeOf(context)` to disable server-only controls with "Needs a connection".
- On successful mutation, re-fetch the contest (or apply the returned `Contest` projection) so the current-value chips stay live.

`contest_control_spec.dart` is the key pure unit — given a `Contest`, it returns the ordered list of `ContestControlSpec`s. This is where all the "when is a control shown vs. hidden vs. disabled, and why" logic lives, and where the unit tests focus.

## State-based visibility logic (derived from `Contest`)

| Control                   | Shown when                                                    | Disabled when (reason)                                                                                   |
| ------------------------- | ------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Open/Close scoring        | Always (value = `scoringOpen`)                                | offline/remote-unreachable → "Needs a connection"                                                        |
| Lock/Unlock admin         | Always (value = `adminLocked`)                                | (locked blocks config/participant/matrix changes, not the control)                                       |
| Complete contest          | `lifecycle` Running (or the "looks finished" suggestion)      | already `Completed`; offline → needs connection                                                          |
| Publish/Delist/Visibility | `publication != null` shows visibility + delist; else Publish | not published → no visibility/delist; offline → needs connection; `publishingEnabled` off → 409 surfaces |
| Archive (local)           | Always (value = `archived`)                                   | purely local — works offline (no API method yet; stub)                                                   |
| Hide results (local)      | Always                                                        | disabled stub — no backend yet                                                                           |

## Test plan (mirrors the analysis docs' unit-test style)

- **`contest_control_spec_test.dart`** — the core: hand-built `Contest`s for each lifecycle/state; assert which controls appear, their value label, enabled/disabled, and disabled reason. Covers: Created, Configuring, Ready, Running, Completed, Locked, Published/Unlisted, Published/Public, Delisted, offline.
- **`contest_control_actions_test.dart`** — fake `ApiClient`: assert the correct request (action + `baseRevision`), 409 → conflict result, network error → offline result, success → returned projection.
- **Widget tests** — one row in each state (enabled, disabled+reason, busy); a dialog opens on lock/complete/publish/delist and the confirmation text lists the blocked items; a snackbar fires on open/close scoring.

Run with `flutter test` in the contest app (per the app's AGENTS.md).

## Outstanding tickets relevant to this work

| Design piece                                                               | Gate                                         | Status (10 Oct 2026) |
| -------------------------------------------------------------------------- | -------------------------------------------- | -------------------- |
| Page layout / placement of the controls section                            | #120 Contest workspace shell                 | Open                 |
| "Completed-by / locked-by" wording the lock/complete dialogs can reference | #345 Audit trail + per-contest read API      | Open                 |
| Complete dialog's "missing scores" group (reuses the Progress derivations) | #342 Workspace facts / #345                  | Open                 |
| Hide-results control (repository, API, client read)                        | follow-up (no backend today)                 | Out of scope         |
| Archive control (API method, client)                                       | follow-up (no backend today)                 | Out of scope         |
| `publishingEnabled` bootstrap flag                                         | one-line bootstrap change in the contest app | To verify            |

## Recommended sequencing

1. Verify the `publishingEnabled` flag is on in the contest app's bootstrap so publish/visibility are live.
2. Build `contest_control_spec.dart` (the pure `Contest` → controls decision) with tests first — it is fully unit-testable and drives everything else.
3. Build `contest_control_actions.dart` (the `ApiClient` invocations + 409/network mapping) with a fake-client test.
4. Build the row widget, the four confirmation dialogs, and the container; wire into `contest_workspace_page.dart` with the offline signal and per-control busy state.
5. Add widget tests for the states and dialogs.
6. Leave hide-results and archive as disabled stubs; raise two follow-up issues for their backends.

## Conclusion

Section 4 of the design — the Contest controls — is **largely ready to implement**. Five of the six logical control groups (open/close scoring, lock/unlock, complete, publish, visibility/delist) are backed by the current API client and server handlers, and all current values live on the `Contest` model already read by the page. The work is a well-bounded, additive UI task in `soar_score_contest`, following the app's existing "pure static helper + page calls `ApiClient` directly" convention.

The two decisions to make up front:

1. **How to treat the two unbacked controls** (hide-results, archive) — recommended: disabled stubs with explicit "not yet available" reasons plus two follow-up issues, keeping this ticket shippable.
2. **Confirming `publishingEnabled` is on** in the bootstrap (one-line change) so the publish controls are live.

The most important thing to validate before starting is the **`publishingEnabled` bootstrap flag**.

## Open questions (don't silently resolve)

1. **Hide-results**: in scope for #250 (needs a new `Contest` field + action + server + client) or a separate issue? Recommendation: disabled stub now.
2. **Archive**: same — no API method exists; stub or separate issue?
3. **`publishingEnabled`**: confirm the contest app's embedded server should have it on (one-line bootstrap change).
4. **Close-scoring Undo**: the brief says "undo where safe" — recommendation: offer Undo only on close-scoring (reopen); confirm no other immediate action needs it.
