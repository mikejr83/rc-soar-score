# PilotImportLink

**Purpose:** Remembers a director's confirmed association between a GliderScore 6 pilot and a participant profile. Both pilot and competition imports use the same association.

**Identifier:** `id` (UUIDv7). The unique source key is (`owner_account_id`, `source_system`, `source_pilot_no`).

| Field                      | Description                                                                                       |
| -------------------------- | ------------------------------------------------------------------------------------------------- |
| `id`                       | Link identifier.                                                                                  |
| `owner_account_id`         | Director who owns and synchronizes the link.                                                      |
| `source_system`            | Currently `gliderscore6`, one logical source per director.                                        |
| `source_pilot_no`          | Pilot number in GliderScore.                                                                      |
| `participant_profile_id`   | Confirmed participant profile.                                                                    |
| `source_values`            | Normalized pilot details from the last confirmed import, used to detect changes requiring review. |
| `created_at`, `updated_at` | UTC timestamps.                                                                                   |
| `revision`                 | Revision used for synchronization and stale-write detection.                                      |

The link is director-scoped and travels through the director synchronization stream. Participant deletion removes active links through the synchronized unit of work. Two installations may create a link for the same source pilot offline: the service keeps the first, records the other installation's latest edit as a `ConflictRecord` (`unique_violation`) that the director decides in Account sync, and replaces that record whenever either link changes, so a decision always refers to the comparison that was shown. Links to the same participant need no decision, and a link whose participant was deleted is refused or removed. Historical import provenance remains separate. Distinguishing a transferred database from an independent database on another computer is deferred.
