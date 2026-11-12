# RC Soar Score Architecture - Sync Protocol

## Purpose and Scope

This document specifies the wire protocol between a native installation (the client) and the service. It turns the rules in [offline-synchronization.md](offline-synchronization.md) into request and response shapes, a reason-code list, versioning rules, paging, idempotency and a required call order. The DTOs in `soar_score_api` (#85), the acceptor (#86), the `SyncStore` contract (#87) and the client engine (#88) must match it. If an implementation needs to differ, change this document first.

Entities referenced here are defined under [`plan/data-model/entities/`](../data-model/entities/): `Installation`, `InstallationActivation`, `MutationRecord`, `SyncCursor`, `ConflictRecord`, `Tombstone` and `AuditEvent`. Web applications hold no contest data and never use this protocol.

## Conventions

- All routes sit under `/api/v1` and require an authenticated director session (bearer token). The protocol version is carried in the request body, not the route.
- Bodies are JSON. Identifiers are UUIDv7 strings. Timestamps are UTC ISO 8601.
- Field names are `snake_case` on the wire, matching the data model.
- Server time is authoritative for ordering. `client_time` is kept for audit only and is never used to order or resolve changes.
- Derived values (normalized scores, totals, rankings, team scores) are never sent as input and never synchronized. The service recomputes them.

## Versioning

Two integers travel in every sync request:

- `protocol_version`: the shape of this protocol. Starts at 1.
- `schema_version`: the client's local data schema version.

The service publishes the supported range of each in the response to `GET /sync/info` and in every error that rejects a version. Before processing anything, the service compares the request to the range:

| Client position                      | Response                                     | Client behaviour                                |
| ------------------------------------ | -------------------------------------------- | ----------------------------------------------- |
| `protocol_version` outside the range | `426`, reason `unsupported_protocol_version` | Stop syncing, show a forced-update message      |
| `schema_version` below the minimum   | `426`, reason `schema_too_old`               | Stop syncing, show a forced-update message      |
| `schema_version` above the maximum   | `409`, reason `unsupported_protocol_version` | Stop syncing, tell the director to update later |
| Both within the range                | Request is processed                         | None                                            |

Adding an optional field does not change `protocol_version`. Removing or changing the meaning of a field does. The service supports the current version and at least the one before it.

## Routes

| Method and path                             | Purpose                                                                          |
| ------------------------------------------- | -------------------------------------------------------------------------------- |
| `GET /sync/info`                            | Supported protocol and schema ranges, server time                                |
| `POST /installations`                       | Register an installation for the account                                         |
| `GET /installations`                        | List the account's installations                                                 |
| `POST /installations/{id}/revoke`           | Revoke an installation                                                           |
| `POST /contests/{contestId}/activations`    | Activate an installation as the contest's administration installation            |
| `POST /sync/exchange`                       | Push unsent mutations and pull changes for one scope                             |
| `GET /sync/system-data`                     | Pull-only system data stream                                                     |
| `POST /sync/conflicts/{conflictId}/resolve` | Submit a director's decision for a conflict                                      |
| `GET /contests/{contestId}/download`        | Complete contest download for initializing a replacement installation            |
| `GET /contests/{contestId}/export`          | Full export including audit history, conflicts, tombstones and pending mutations |
| `POST /contests/import`                     | Import an export, preserving identifiers                                         |

## Scopes

A scope is either a contest (`contest_id`) or the director's own data (`owner_account_id`), such as participant profiles, roles, models, landing tables and presets. Exactly one is set. Each scope has its own strictly increasing `sequence`, assigned by the service when it accepts a change. Cursors, paging and conflicts are always per scope.

System data (shipped profiles, system roles, landing tables) is not a scope. It only comes down, driven by `Installation.system_data_seq`.

## Installation Registration and Activation

**Register** (`POST /installations`): the client sends its generated `id`, `label` and `platform`. The service returns the stored `Installation`. Registering the same `id` again for the same account returns the existing row. A revoked installation cannot sync.

**Revoke** (`POST /installations/{id}/revoke`): sets `revoked_at`. Later exchanges from that installation are rejected with `inactive_installation`.

**Activate** (`POST /contests/{contestId}/activations`): the body carries `installation_id` and `kind` (`Initial`, `Replacement` or `Reclaim`). It requires an authenticated session of the contest's owning account. In one transaction the service ends the previous open `InstallationActivation` row (if any) and creates the new one, so a contest never has more than one open activation. `Reclaim` additionally requires that the installation has pulled to the current sequence and has no unresolved conflicts that need action; otherwise the service returns `409` with reason `reclaim_requires_sync`. The client asks for the explicit "Reactivate as Primary and Sync" confirmation before calling it.

## Sync Exchange

`POST /sync/exchange` handles one scope per request.

### Request

```json
{
  "protocol_version": 1,
  "schema_version": 1,
  "installation_id": "…",
  "scope": { "contest_id": "…" },
  "last_acknowledged_sequence": 41,
  "page_token": null,
  "mutations": [
    {
      "id": "…",
      "client_mutation_id": "…",
      "entity_type": "score_revision",
      "entity_id": "…",
      "base_revision": 3,
      "authority": "Director",
      "client_time": "2026-10-13T12:00:00Z",
      "depends_on_mutation_id": "…",
      "payload": {}
    }
  ]
}
```

- `scope` is `{"contest_id": …}` or `{"owner_account_id": …}`.
- `mutations` are in dependency order: a mutation appears after the one it names in `depends_on_mutation_id`. A matrix revision is therefore sent before the scores that reference it. An empty list is valid and means pull only.
- A deletion is a mutation whose payload marks the entity deleted. It creates a `Tombstone` on the server. The change that reaches other installations for it has the payload `{"deleted": true}`.
- A matrix move carries `supersedes` in its payload data, naming the assignment it replaces. The service marks that assignment superseded in the same transaction.
- `page_token` is null on the first request of an exchange. It is set only to continue a paged pull (see Paging).

### Response

```json
{
  "protocol_version": 1,
  "results": [
    {
      "client_mutation_id": "…",
      "outcome": "Accepted",
      "revision": 4,
      "sequence": 42,
      "reason_code": null,
      "current_revision": null,
      "depends_on": null
    }
  ],
  "changes": [
    {
      "sequence": 42,
      "entity_type": "…",
      "entity_id": "…",
      "revision": 4,
      "payload": {}
    }
  ],
  "conflicts": [{ "id": "…", "requires_action": true }],
  "next_page_token": null,
  "server_sequence": 57
}
```

- `results` has exactly one entry per submitted mutation, in request order.
- `outcome` is one of `Accepted`, `Rejected`, `Conflict` or `Skipped`.
  - `Accepted` carries the new `revision` and the assigned `sequence`.
  - `Rejected` and `Conflict` carry a `reason_code` and the entity's `current_revision`. A `Conflict` also creates a `ConflictRecord` listed in `conflicts`.
  - `Skipped` carries the failed mutation in `depends_on`. The service did not attempt it.
- `changes` are all accepted changes after `last_acknowledged_sequence`, in sequence order, including changes from other sources such as accepted participant scores and server-created placeholders. The client's own accepted mutations are included so the client can confirm the stored revision.
- `server_sequence` is the scope's highest sequence when the response was built.

Each mutation commits or fails independently. A rejection never rolls back valid siblings in the same batch.

### Paging

When more changes exist than fit in one response, the service returns the first page and a `next_page_token`. The client repeats the request with the same `last_acknowledged_sequence`, `page_token` set and `mutations` empty, until `next_page_token` is null. The server does not re-apply mutations on continuation requests. A token is opaque, tied to the scope and installation, and valid for at least one hour; an expired token returns `410` and the client restarts the pull from its stored cursor. The default page size is 500 changes and the service may lower it.

### Idempotency

The service applies a mutation at most once, keyed by `(contest_id, client_mutation_id)` or `(owner_account_id, client_mutation_id)`. A retry of an already-decided mutation returns the original `results` entry unchanged and creates nothing new. This makes a repeat after a timeout safe: if the server committed but the client never saw the response, the retry returns the recorded outcome.

Pulls are idempotent by nature. Re-requesting from the same `last_acknowledged_sequence` returns the same changes plus anything accepted since.

## Order a Client Must Call Things

1. `GET /sync/info`. Check both version ranges. Stop on a version error.
2. Register the installation if it is new (`POST /installations`).
3. `GET /sync/system-data` from `system_data_seq`, if behind.
4. For each scope in turn, **pull first**: `POST /sync/exchange` with empty `mutations`, following `next_page_token` until it is null. Preserve unsent local mutations and audit history, then store the changes through the replicated-change path (they must not create new pending mutations), and only then advance the local `SyncCursor` to the highest sequence stored.
5. Push: `POST /sync/exchange` with the `Pending` mutations in dependency order. Update each local mutation from its `results` entry. Acknowledged mutations are cleared, rejected ones stay with their reason, `Skipped` ones are retried after their dependency is accepted.
6. Store any returned `changes` and advance the cursor as in step 4.
7. For a conflict that needs action, wait for the director's choice and call the conflict-resolution route, then sync the scope again.

A client that reconnects after being offline always starts with step 4. It never pushes before it has pulled.

A deactivated installation (no open `InstallationActivation` for the contest) can pull and export but its administrative mutations are rejected with `inactive_installation`.

## Conflict Resolution

`POST /sync/conflicts/{conflictId}/resolve` carries `client_mutation_id`, `choice` (`KeptAccepted`, `TookCompeting` or `Merged`) and, for `Merged`, the merged `payload`. It is itself a mutation: it is idempotent, ordered in the scope's sequence and audited. It returns the same `results` entry shape. Only conflicts with `requires_action` true are offered for a decision. Silent records (a director's value beating a participant submission) are returned in `changes` and `conflicts` with `requires_action` false and are never discarded.

### Conflict records as changes

A `ConflictRecord` reaches every installation of its scope through the normal stream, as a change with `entity_type` `ConflictRecord` (the stable entity name every other change uses). The entry in `conflicts` of an exchange response only points at it; the change carries the content. The client stores it through the replicated-change path like any other change, so the cursor and idempotency rules apply unchanged.

The change `payload` is the `ConflictRecord` fields plus the two values the side-by-side view needs, so a client never has to look up a mutation it does not hold (the competing one may have come from another installation or a participant):

| Extra field         | Meaning                                                                     |
| ------------------- | --------------------------------------------------------------------------- |
| `accepted_payload`  | The entity state the service applied; null while no change has been applied |
| `competing_payload` | The entity state of the colliding mutation, as submitted                    |
| `entity_revision`   | The entity's current revision, so a resolution can be based on it           |

Resolving a conflict writes a new revision of the same `ConflictRecord` entity (`resolution`, `resolution_choice`, `resolved_at`, `resolved_by`), which is delivered the same way. A record with `requires_action` false is silent: it is stored and shown in the score history, but it is not counted as needing action. The raw `MutationRecord` rows of other installations are never sent.

## Full Download, Export and Import

- **Download** returns the complete current contest state and the scope cursor, enough to initialize a replacement installation. It carries the same `schema_version` and `protocol_version` checks as an exchange.
- **Export** returns everything in the download plus raw score revisions, audit history, conflicts, tombstones, pending mutations and publication references.
- **Import** preserves identifiers. If a contest with the same `id` already exists it returns `409` with reason `contest_exists` and changes nothing. It never silently overwrites.

Both are recovery operations, not the normal conflict mechanism. Large responses use the same paging shape as an exchange.

## Reason Codes

One list, shared by server and client, defined in `soar_score_core`:

| Code                        | Used with          | Meaning                                                                        |
| --------------------------- | ------------------ | ------------------------------------------------------------------------------ |
| `stale_base`                | Conflict, Rejected | `base_revision` is not current and the change cannot be merged automatically   |
| `config_revision_conflict`  | Conflict           | Configuration changed on a stale revision; side-by-side resolution is required |
| `inactive_installation`     | Rejected           | No open activation for the contest, or the installation is revoked             |
| `unknown_matrix_revision`   | Rejected           | A score references a matrix revision the service does not have yet             |
| `unknown_flight_group`      | Rejected           | A score references a group the service does not have yet                       |
| `entity_deleted`            | Rejected           | The entity has a tombstone                                                     |
| `unique_violation`          | Conflict           | For example two moves into the same lane                                       |
| `invalid_payload`           | Rejected           | The payload is malformed, names a derived value, or is not a stored entity     |
| `locked`                    | Rejected           | The score or contest state does not allow modification                         |
| `unauthorized`              | Rejected           | The account lacks authority for the scope or the entity                        |
| `director_over_participant` | Conflict (silent)  | A director's official value beat a participant submission                      |
| `not_link_manager`          | Rejected           | Another installation manages the director's remembered GliderScore pilot links |

**Remembered pilot links.** The first installation to write a `PilotImportLink` of a director manages the links. The service rejects link saves and deletes from any other installation with `not_link_manager`, whether live or queued, except the deletion of links that went with a deleted participant. Decisions and the service's own changes are never refused. A director's choice on an existing disagreement (`unique_violation`) may name another participant (`merged` with `participant_profile_id`), which is checked when the decision is saved.

| `scored_assignment` | Rejected | A change would reinterpret an assignment that already has scores |
| `dependency_failed` | Skipped | A mutation it depends on failed |
| `unsupported_protocol_version` | Version error | Protocol version outside the supported range |
| `schema_too_old` | Version error | Client schema below the minimum |
| `reclaim_requires_sync` | Activation error | `Reclaim` attempted before pulling and reconciling |
| `contest_exists` | Import error | A contest with that identifier already exists |

`Rejected` means the mutation is invalid and stays in the outbox with its reason until the director retries or discards it. `Conflict` means a decision is needed (or a silent record was stored). `Skipped` is retried automatically.

## Authority and Resolution

The acceptor applies the authority table in [offline-synchronization.md](offline-synchronization.md#authority-and-conflict-resolution). Last-write-wins is never used for authoritative data. Original score attempts are immutable; official scores follow the director's latest authorized decision; locked scores and states that disallow modification are rejected with `locked`. Derived values are never accepted as input.

## Current implementation notes

- The first accepted upload for a contest from the director's installation creates the `Initial` activation when none exists, so the engine does not call the activation route for a first upload.
- The lock and completed rules do not apply to the other mutations of the exchange that creates a contest (its first upload): they are the contest's history, so a restored or offline-completed contest uploads in full. Later exchanges are refused as usual.
- A first upload too large for one exchange is sent in several (the service's limits are 16 MiB and 10,000 mutations per exchange, `soar_score_api` `sync_limits.dart`). Every exchange of it sets `first_upload: "open"`. The exchange that creates the contest opens the upload (`upload_open` on the contest's `Initial` activation); while it is open, an exchange from that installation that says `open` keeps the contest's history exempt from the lock and completed rules. When every mutation of the upload is decided the client sends an exchange with `first_upload: "finish"` and no mutations, which closes the upload; after that the exemption is gone and the ordinary rules apply. The client sends the contest's creation again, and resumes with the flag, until it has sent the finish, so an interrupted upload continues. A first upload sent in one exchange never opens the upload. A mutation too large to fit alone is rejected locally with `payload_too_large`, and a mutation that depends on a refused one is not sent until the refusal is resolved. Between the first and the last exchange another installation that pulls the contest sees it partly uploaded.
- `GET /sync/system-data` answers an empty page at the seeded sequence until system data changes are published.
- Exchanges for one scope are serialized with an in-process lock. A deployment with several service instances needs a database lock.

## Tombstones

A deletion mutation creates a `Tombstone` in `Pending` status and sets it `Acknowledged` when the service accepts it. Acknowledged tombstones are kept for 90 days (`purge_after`). A later change to the deleted entity is rejected with `entity_deleted`.

## Privacy

Responses are scoped to the authenticated director's authorized data. Participant email addresses and other private data follow the privacy rules in the participant requirements and are not included in changes unless the director is entitled to them.

## Errors

Transport-level errors use the standard API error shape. Auth failures return `401` (client reports "token expired" and refreshes), unavailable scopes `403`, server faults `5xx` (client reports "server error" and retries with backoff). Mutation-level problems are never HTTP errors: they appear in `results` so one bad mutation never fails the batch.
