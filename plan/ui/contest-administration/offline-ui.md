# RC Soar Score User Interface - Offline Application Frame

The desktop shell reuses the contest-management application and adds local status and recovery controls. Offline mode must preserve the ability to administer a contest without remote connectivity.

## Offline-capable pages

The native application works offline on these pages. Decision: [#81](https://github.com/mikejr83/rc-soar-score/issues/81).

- Score entry, matrix and round groups, official scoring and standings, and a pilot's earlier scores.
- The new-contest wizard and contest configuration.
- The participant editor, using local pilot and model data. Matching against remote participant data shows as unavailable.
- System data management: models, participant roles and landing bonuses.
- Reports and exports from local data.
- Contest list actions: create, delete and delist, with offline handling.

The full recovery tools (complete export and import, conflict inspection, destructive-action warnings) are tracked separately and are not part of this page list. Publishing, self-scoring invitation links, QR codes and sign-in need a connection.

For the first release the synchronization status is minimal: a pending-count badge and the last synchronized time. Conflict detail arrives with the synchronization work (#83).

## Connectivity status

The frame shows separate indicators for:

- Internet connectivity.
- Remote API connectivity.
- Local application storage availability.

Each indicator has a text label and a detail view with the last observed time and a retry action. Internet connectivity does not imply remote API connectivity.

## Synchronization status

For account-backed contests, show:

- Last successful synchronization time.
- Remote contest revision and local contest revision.
- Number of queued mutations.
- Number of conflicts or rejected mutations requiring action.
- Active administration-installation identity.

For an accountless local contest, show `Local only` and explain that no remote backup exists. Offer `Sign in` to enable synchronization where supported. Anonymous publishing is separate and must not be presented as backup synchronization. Self-scoring invitation links and QR code generation are disabled in the UI for 100% offline un-synced contests, with a message explaining that an initial sync is required before invitations can be issued. Once synced, links and QR codes already issued keep working and print offline; issuing new ones needs a connection. The message never refers to opening participant scoring, which does not issue invitations.

Selecting the sync status opens a detail view. The director can inspect a mutation, its base revision, reason for rejection or conflict, local and remote values, and available actions. The UI must preserve unsent local values and audit history while resolving a conflict. A failed sync never blocks offline administration.

## Automatic sync

The frame provides a toggle with `Automatic` and `Manual` states for account-backed contests. Automatic mode queues and retries synchronization when a connection is available; it never publishes a contest and never silently resolves an authority conflict. Manual mode displays an always-available `Sync now` action when the remote API is reachable.

Before an automatic sync sends mutations, the UI may show a non-blocking progress state. It must show completion, partial failure, and conflict results. Retrying is safe and must not duplicate accepted mutations.

## Publishing

Publishing is a separate action on contest configuration. The offline frame may show publish availability, but it must not label a successful backup sync as publication. A publish action requires a remote connection and shows the target private revision, visibility, and update policy before confirmation. Anonymous publishing uses the email verification flow and does not enable ordinary synchronization.

## Exporting and importing a contest

The native app only. On the contests page, the detail pane has `Export…` and the page has `Import contest…` (also on the empty state). The web build has neither, as it holds no contest data.

**Export.** A dialog names the contest and offers one checkbox, `Remove email addresses`, on by default (turn it off for a full backup). It says the file is not encrypted and is not sent anywhere. `Save file…` opens the system save dialog for a `.rcsoar` file; a snackbar names the saved file.

**Import.** The system file chooser opens first, then a dialog shows the contest name, when and from whom it was exported, the participant, round and score counts, and whether email addresses were removed.

- A file the app cannot import (not a contest file, newer format, other schema version, a contest id already here, a row clash) shows the reason, names the existing copy when there is one, and offers no way on.
- Otherwise two modes are offered. `Open as a local copy for inspection` is the default: it stays on this computer and is never synced, whoever is signed in. `Import as an editable copy` makes the importing account the owner, like a contest made here, and says the original installation may still run the contest until it is moved here. A mode that is not available shows why and cannot be picked.

**Labels.** A contest imported for inspection is marked `Imported copy, not synced` in the detail pane, with a sentence saying it stays on this computer. Creating a participant inside such a contest makes the profile for that contest's inspection owner.

**Not yet built.** The label in the contest list rows and the workspace, and grouping the global participant, role and landing-table pages by source (`Imported from <label>`); those pages already list the imported rows with the account's own.

## Recovery and warnings

The frame provides export and import actions for complete local contest data. Export includes raw scores, revisions, audit history, tombstones, and pending mutations. Import must preserve identifiers and must warn before creating or merging with an existing contest.

When the local installation has unsynchronized mutations, warn before uninstall, reset, replacement activation, or other destructive storage actions. Explain that changes after the last successful sync cannot be recovered if the installation is lost.
