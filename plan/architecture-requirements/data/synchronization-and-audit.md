# Synchronization and Audit

## Mutation and synchronization records

Every synchronizable entity has a stable ID, contest ownership where applicable, and a revision. A mutation stores entity ID, base revision, unique client mutation ID, actor, authority, source installation/device, client time, and server acceptance/rejection time.

A synchronization cursor and acknowledgement record belong to an authorized installation and contest scope. The service applies a mutation at most once, returns acknowledgements/rejections/conflicts and changes after the cursor, and advances the cursor only after local durable storage.

## Installation authority

Each contest has one active administration installation. It is the offline authority for configuration, matrix, official scores, state transitions, and deletions. Replacement activation revokes the previous installation's mutation authority; its later changes are rejected as inactive-device mutations.

The installation that holds administrative authority over a contest is recorded on the server, with a history of each handover, so that no device can edit it. A contest has one such installation in the first release. Director-owned data that belongs to no contest synchronizes through its own sequence stream.

## Conflicts and tombstones

Conflicts preserve both versions and the reason a decision is required. Official decisions take precedence over participant submissions, but losing participant submissions remain as pending or silent review records. Derived values are recalculated, never merged as source data.

Local deletion creates a tombstone until acknowledged. Tombstones prevent older changes from recreating records and are kept for 90 days after the server acknowledges the deletion. Deleting a published contest deletes only the director's data; its published record remains.

## Audit events

Audit events identify contest/entity, action, actor, authority, installation/device, base and resulting revisions, server/client timestamps, reason, and outcome. They cover state transitions, score attempts and decisions, reviews, invitations, publication attempts, synchronization conflicts, rejected mutations, deletion, restoration, and installation activation. Sensitive credentials and private message contents are excluded.

Complete export/import includes identifiers, revisions, raw scores, derived metadata, audit history, conflicts, tombstones, pending mutations, and publication references. Import preserves IDs and does not silently overwrite an existing contest.
