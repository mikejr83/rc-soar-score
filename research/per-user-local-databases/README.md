# Per-account local databases in the native contest app (2026-11-08)

Evaluation only. No code changed for this proposal, no tickets filed. It follows an investigation of contests "going missing" in the Windows app after the hosted server was reset (see "Background"). Status: proposal from Mike, parked for discussion.

## Question

Today one OS user has one local SQLite database. Should the native app instead keep a **separate database folder per signed-in account** under that OS user's application-support directory, so that:

- the app always opens the folder of the account that last signed in, signed in or not (signed out, or offline);
- when a different account signs in, the app asks whether to **transfer** the current local data to the new account or to **start a new local session** for it in a new folder;
- the app tells the director which cached data they are working with while offline?

## Recommendation in one paragraph

The idea fits the offline-first design and removes the open problem from the account-claim work: two registered accounts signing in on the same OS user can no longer hide each other's data, because each account has its own folder. Build it as a thin layer **around** the existing bootstrap: a small profile index file picks the folder before the embedded server starts, and a profile switch tears the bootstrap down and starts a new one (a restart of `NativeBootstrap`, not live swapping of the database). Do not make the data-moving "transfer" the default path. A transfer rewrites ownership of contests the previous account may still own on the service, so it needs a clear warning and a fresh decision from the director each time. The largest costs are the bootstrap restart and the migration of existing installs, not the folder layout itself.

## Background: how the app stores things today

Everything below was read from the code on 2026-11-08.

- **One database per OS user.** `NativeBootstrap.databasePath` returns `soar_score.db` (or `soar_score_demo.db` in demo mode) inside `getApplicationSupportDirectory()`, which on Windows is `%APPDATA%\<organization>\<app>`. Another Windows user has a different `%APPDATA%` and so a different database. That part of the model already works.
- **Files that sit beside the database:** `soar_score.db` with `-wal`, `-shm` and `-journal` files; `soar_score.db.installation-id` (`InstallationIdFile.besides`), which the service uses to recognise this installation; and `soar_score_ui.db` (`openLocalUiStore(directory: dirname(database))`), which holds theme, text size, hidden panels and drafts, keyed by account id.
- **The sign-in is not in the database.** The Windows session lives in `flutter_secure_storage` (DPAPI, per OS user) under the key `auth0_credentials`. It is one slot per OS user, so there is exactly one remembered sign-in per OS user. Switching accounts replaces it.
- **Ownership.** Every contest and director record carries `owner_account_id`. A fresh installation owns what it creates as its **Local account** (`local_account` table). On sign-in `LocalAccountClaimer` asks the service to record the claim, then `reassignTo` rewrites every Local-account reference in the database to the signed-in account and the app acts as that account.
- **Visibility is by owner.** The embedded API lists only contests whose owner is the acting account (plus inspection owners). That is why data owned by one account is invisible to another account, and to the Local account.
- **Startup order today:** open database and embedded server, then `auth.restore()`, then the sync engine and claimer. The database is chosen before the sign-in is known.

### The bug that prompted this

In run 1 the claim re-pointed the demo contests to the signed-in account. In run 2 the API server was down, the claim could not run, and the app started as the Local account, which owned nothing. The data was intact but invisible. A first fix (uncommitted at the time of writing) stores the claimed account in `local_account.linked_account_id` and starts as that account, and keeps showing it after sign-out. That fix is correct for one account per database. It does not answer what should happen when a **second** account signs in.

## Proposed design

### Layout

```
%APPDATA%\<org>\<app>\
  profiles.json                      index: profiles, last active, per-profile metadata
  profiles\
    local\                           data made before any sign-in (the Local account)
      soar_score.db
      soar_score.db.installation-id
      soar_score_ui.db
    a1b2c3d4...\                     one folder per account
      soar_score.db
      soar_score.db.installation-id
      soar_score_ui.db
  demo\                              demo mode keeps its own root (never mixed with real data)
```

- **Key:** the account's stable identifier, the Auth0 subject (`sub`) as returned at sign-in, not the email, which can change. The folder name is a hash of the key, so it is filesystem-safe and does not put an email address on disk in a path.
- **`profiles.json`:** `{ "version": 1, "last": "<key>", "profiles": { "<key>": { "folder", "displayName", "email", "lastSignIn", "lastSyncedAt", "accountId" } } }`. It holds display metadata only, no tokens. It is written atomically (write a temp file, then rename). If it is missing or damaged it can be rebuilt by scanning `profiles\` (each database knows its `linked_account_id`).
- **Per profile:** its own database, installation id and UI store. A separate installation id per profile is deliberate: to the service each profile is a separate installation, which is what it is.

### Choosing the folder at startup

1. Read `profiles.json`; take `last` (if none, open `local`).
2. Open that profile's database and start the embedded server as the profile's account (`linked_account_id`, or Local for the `local` profile). This works with no network and no valid token, which is the offline case from the bug.
3. Restore the stored sign-in in parallel. Compare its `sub` with `last`:
   - **Same account (or no sign-in):** carry on; sync starts if a token is usable.
   - **Different account, or a first sign-in:** go to the switch decision below.

The only change to startup order is that the **profile choice comes before the database opens**, using the index rather than the token. The token is checked afterwards.

### Sign-out and offline mode

- Signing out clears the session. The app keeps the `last` profile open, with sync paused. This is what Mike asked for: the app works with the user who last signed in.
- Offline (no network, expired token that cannot refresh) behaves the same way: the profile stays open, edits are saved locally and queued.
- Nothing is deleted on sign-out. Removing a profile's data is a separate, explicit action (see "Forgetting a profile").

### A different account signs in

When the signed-in `sub` differs from the open profile, and the open profile holds data, ask once:

> You are signed in as **B**, but this computer's data belongs to **A** (last synced 3 Nov 14:20, 4 contests, 2 not yet sent).
>
> - **Start a new session for B.** B gets a clean copy of their own data from the service. A's data stays on this computer, untouched, and A can sign back in to it.
> - **Move this computer's data to B.** A's local contests become B's. Choose this only when A and B are the same person (for example a new login for the same director).
> - **Cancel.** Stay as A, sign out of B.

- **Start a new session** is the default and the safe choice. It creates `profiles\<hash(B)>\`, a new empty database and installation id, and sync pulls B's contests from the service. If B already has a folder, it is simply opened (no question needed).
- **Move this computer's data** is the existing claim path generalised: re-point A's references to B (`reassignTo`-style) and rename or merge the folder. See the risk list below. It should not be offered when A's data is already synced under an account on the service, because that data is A's on the service and is pulled again for A anyway.
- If the open profile is the pristine `local` profile with **no data**, skip the question: just open or create B's folder.
- If the open profile is `local` **with** data (created offline before any sign-in), the usual claim applies: the question is "Add this computer's offline work to B?" with Yes (claim, as today) and No (keep as a separate `local` profile, then open B's folder).

### Switching the running app

`NativeBootstrap` builds one embedded server, one sync engine, one claimer, one preferences controller and one UI store, all tied to one database. The simplest correct switch is:

1. Finish or cancel in-flight work, and refuse a switch while a draw, import or sync push is mid-flight, or wait for it.
2. Call `NativeBootstrap.close()` (which already stops the claimer, the sync engine, the server, the UI store and the remote client).
3. Write `last` in `profiles.json`.
4. Start a new `NativeBootstrap` on the new folder and rebuild the widget tree from it.

Doing this in-process requires the app root to own the bootstrap and be able to replace it (today `main.dart` starts it once). A cheaper first version is to write the choice and **restart the app** (`quitApplication()` exists), at the cost of a visible relaunch. Recommend the in-process restart of the bootstrap, with the relaunch as a fallback.

### What the app shows about the data it is using

When the open profile is not the freshly synced account, the director should always be able to see **whose cached data this is and how old it is**. Proposal:

- **Status chip in the shell** (the existing offline frame/status panel, `shell_status_panel.dart`): `Offline · A · last synced 3 Nov 14:20`, and `Signed out · A's cached data`.
- **Banner on the contest list and workspace** while the sign-in does not match the open profile (signed out, or offline with an expired token): "You are working with a copy of A's contests stored on this computer. Changes are saved here and will be sent when A signs in." (Words need review; use ARB.)
- **Per-contest line** on the contest list: pending-change count and last-synced time, which `AppSync` already tracks.
- **Account menu** (`shell_account_button.dart`): a "Profiles on this computer" entry listing each profile with name, email, last sync, and Switch / Forget actions.
- Make sure the **Settings** page (theme, text size, time zone) is per profile, since the UI store is.

## Interaction with existing pieces

| Piece                                   | Effect                                                                                                                                                                                  |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `local_account.linked_account_id` (new) | Still useful inside a profile. It lets the profile open as its account offline. `profiles.json` can then be rebuilt from the databases. Could be dropped if the index alone is trusted. |
| `LocalAccountClaimer`                   | Runs per profile. Claims only the `local` profile's data (or the transfer path). Needs the "which profile am I" input.                                                                  |
| `ActingAccount` / `ActingUiAccount`     | Unchanged within a profile. Sign-out no longer changes the acting account.                                                                                                              |
| `NativeSync` and sync positions         | Per database, so positions do not collide. `Director` scope positions already move on `reassignTo`; a transfer must repeat that.                                                        |
| `InstallationIdFile`                    | One per profile, in the profile folder.                                                                                                                                                 |
| `soar_score_ui.db`                      | One per profile (drafts, panels, theme). The wizard draft is already keyed by account.                                                                                                  |
| Secure-storage session                  | Still one slot per OS user. Not changed by this proposal; the profile list is the memory of previous accounts, not of their tokens.                                                     |
| Demo mode                               | Own root (`demo\`), single profile, reset deletes the whole folder. Demo data never joins a real profile. In demo mode the claim should not run against a real service.                 |
| E2E scripts                             | `scripts/e2e-contest.ps1` passes the demo defines and deletes the demo database. They need to follow the new demo path.                                                                 |

## Risks and open questions

1. **Transfer rewrites ownership across accounts.** `reassignTo` was designed for "my own offline work becomes my account's". Applying it from A to B moves contests A owns on the service. The service refuses a claim by anyone else, and the sync layer would see contests B did not create. Decide whether "Move" is allowed at all, restricted to unsynced data, or limited to the `local` profile. Recommendation: allow it only for the `local` profile and for data that has never synced; treat A-to-B as "start a new session".
2. **Duplicate edits of one contest.** If A and B are the same director with two accounts, or a contest is shared, two profiles can each hold a copy and edit it. Sync conflict handling already exists, but the director may be confused by the same contest in two profiles. The "Profiles" menu should make it clear which is which.
3. **Unsynced work in an old profile.** A's pending changes stay in A's database until A signs in again. If A never does, they are never sent. The profile list should show "N changes not sent" and offer Export (`.rcsoar`, already exists) before Forget.
4. **Profile switch while busy.** Draws run in an isolate, imports run external processes, sync pushes and printing are asynchronous. A switch needs a guard (wait, then close) and a test.
5. **Identity of the sign-in at startup.** The last profile opens before the token is checked. If the stored token belongs to a different `sub` (signed in as B on another day), the mismatch question has to be asked at startup, before showing A's data as B's. The token's `sub` must be readable without a network call (decode the stored ID token or keep `sub` beside the session).
6. **Migration of existing installs.** The current `soar_score.db`, installation id and UI store sit directly in the support directory. On first run of the new version: if the database is linked to an account, move the files into `profiles\<hash>\`; if not, into `profiles\local\`. The database schema is still version 1 and edited in place (a stale local file must be deleted after a schema change), so alpha testers may already have to reset; decide whether a file move migration is worth writing now.
7. **Disk use.** Each profile is a full SQLite database. Contests are small, but a director with a long history syncs it all per profile. Probably fine; show the size in the Profiles menu.
8. **Privacy on shared OS users.** If several people share one Windows login, every profile folder is readable by whoever uses it, and the stored sign-in is one slot. Separate profiles do not make that safe; the guidance stays "use separate Windows accounts". Worth stating in the install docs.
9. **Web.** The web build has no local database and no offline mode. This proposal is native-only.
10. **Account deletion or sign-in with a deleted account.** A profile for an account the service no longer knows would stay offline-only. Define how the director gets the data out (Export) and how the profile is removed.

## Forgetting a profile

A "Forget this profile" action in the Profiles menu deletes the folder after a confirmation that states: the account, the contests inside, and how many changes have not been sent (with an Export button). Never delete automatically. Never delete the active profile; switch first.

## Options considered

| Option                                                | What it is                                                                                                  | Verdict                                                                                                                                                                                                             |
| ----------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **A. Linked account in one database**                 | The state after the first fix: one database, remember which account owns it.                                | Good for one account per OS user. A second account hides the first's data and nothing explains it. Keep as the inner mechanism.                                                                                     |
| **B. Per-account folders (this proposal)**            | Index plus one database per account, with a switch decision.                                                | Recommended. Clear mental model, no hidden data, matches "work with the last user offline". Cost: bootstrap restart and migration.                                                                                  |
| **C. One database, many accounts, filter by account** | Keep a single file; list contests by selected account; switch the acting account in place.                  | Smallest folder change but biggest code change: sync positions, installation identity and UI state are all keyed per database. Mixes accounts in one file, which makes "Forget" and export harder. Not recommended. |
| **D. Block the second account**                       | Refuse sign-in for a different account on a linked database, with a message to use another Windows profile. | Cheapest guard. Reasonable stop-gap before B.                                                                                                                                                                       |

## Suggested sequence if this goes ahead

1. Land the linked-account fix (A). It is needed inside any profile.
2. Add the profile index and the folder layout behind the same `NativeBootstrap.start`, with only the `local` profile at first, and migrate existing installs. No behaviour change.
3. Make the bootstrap replaceable at the app root and add the in-process restart.
4. Add the sign-in mismatch decision (start a new session / move / cancel), starting with D as the interim guard.
5. Add the offline and cached-data indicators and the Profiles menu.
6. Update `AGENTS.md` (Page Map, bootstrap notes), the E2E scripts, and the install docs.

## What to decide before building

- Is "Move this computer's data to the new account" in scope, and under what limits (risk 1)?
- Is a relaunch acceptable for the first version of a profile switch, or must it be in-process?
- Should the stored sign-in remember more than one account (one secure-storage slot per profile) so that switching back does not need a browser sign-in? Not proposed here, but the profile list makes it tempting.
- What does the app do in demo mode when the demo database is linked to a real account (skip the claim, or run signed out)?
