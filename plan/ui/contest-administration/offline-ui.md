# RC Soar Score User Interface - Offline Application Frame

The desktop shell reuses the contest-management application and adds local status and recovery controls. Offline mode must preserve the ability to administer a contest without remote connectivity.

## Connectivity status

The frame shows separate indicators for:

- Internet connectivity.
- Remote API connectivity.
- Local application storage availability.

Each indicator has a text label and a detail view with the last observed time and a retry action. Internet connectivity does not imply remote API connectivity.

## Synchronization status

For account-backed data, show the selected contest's stream and the director's own stream separately. The director's own stream carries data that belongs to no contest: participant records, roles, models, landing tables, and presets. For each stream show:

- Last successful synchronization time.
- Remote revision and local revision.
- Number of queued mutations.
- Number of conflicts or rejected mutations requiring action.

For the contest stream, also show the active administration installation.

For an accountless local contest, show `Local only` and explain that no remote backup exists. Offer `Sign in` to enable synchronization where supported. Anonymous publishing is separate and must not be presented as backup synchronization. Self-scoring invitation links and QR code generation are disabled in the UI for 100% offline un-synced contests, with a message explaining that an initial sync is required before participants can self-score.

Selecting the sync status opens a detail view listing the outbox. Each row has a state of `Pending`, `Accepted`, `Rejected`, `Conflict`, or `Skipped`, with its reason code (for example `stale_base`, `inactive_installation`, or `locked`). The director can inspect a mutation, its base revision, reason for rejection or conflict, local and remote values, and available actions. A silent conflict record, such as a participant submission that lost to an official value, stays in the score history and is not listed as needing action. The UI must preserve unsent local values and audit history while resolving a conflict. A failed sync never blocks offline administration.

## Installations

The frame lists the director's installations by label, for example "Field laptop", and shows which one is the active administration installation for the selected contest. When this installation is not the active one, it offers `Reactivate as Primary and Sync`. The action first pulls and reconciles the remote changes, then makes this installation active. The confirmation names the installation that will stop being active.

## Automatic sync

The frame provides a toggle with `Automatic` and `Manual` states for account-backed contests. Automatic mode queues and retries synchronization when a connection is available; it never publishes a contest and never silently resolves an authority conflict. Manual mode displays an always-available `Sync now` action when the remote API is reachable.

Before an automatic sync sends mutations, the UI may show a non-blocking progress state. It must show completion, partial failure, and conflict results. Retrying is safe and must not duplicate accepted mutations.

## Publishing

Publishing is a separate action on contest configuration. The offline frame may show publish availability, but it must not label a successful backup sync as publication. A publish action requires a remote connection and shows the target private revision, visibility, and update policy before confirmation. Anonymous publishing uses the email verification flow and does not enable ordinary synchronization.

## Recovery and warnings

The frame provides export and import actions for complete local contest data. Export includes raw scores, revisions, audit history, tombstones, and pending mutations. Import must preserve identifiers and must warn before creating or merging with an existing contest.

Deletions made offline are shown to the director, listing what will be removed, before they are sent and remove remote data.

When the local installation has unsynchronized mutations, warn before uninstall, reset, replacement activation, or other destructive storage actions. Explain that changes after the last successful sync cannot be recovered if the installation is lost.
