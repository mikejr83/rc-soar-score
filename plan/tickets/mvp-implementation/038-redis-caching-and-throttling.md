# Ticket 038 — Redis Caching and Throttling for Hosted Server

> **This work is being implemented through GitHub issues.** The work items and acceptance criteria below are tracked in epic [#942](https://github.com/mikejr83/rc-soar-score/issues/942) and its sub-issues [#943](https://github.com/mikejr83/rc-soar-score/issues/943) to [#949](https://github.com/mikejr83/rc-soar-score/issues/949). The checkboxes in this file are not updated; follow progress in the issues. This document remains the specification they refer to.

- **Category:** Server / Performance / Cache
- **Priority:** High
- **Status:** Tracked in GitHub issues (this file is the specification only)

## Context

The hosted server (`soar_score_server`) handles public spectators, contest directors, native app synchronization, and participant self-scoring. Several read endpoints and middleware execute expensive operations on every request:

1. **Participant results:** `GET /api/v1/self-scoring/results` and `/rounds/<round>/group-results` calculate live standings on read with `PreliminaryResultsService.calculate()`. It stores nothing in the database, recomputing scores across all rounds on every mobile refresh.
2. **Invitation throttle:** `POST /api/v1/self-scoring/invitations/resolve` uses `RequestThrottleStore` to execute an `INSERT ... ON CONFLICT DO UPDATE` upsert in PostgreSQL per hit.
3. **Public publications:** `GET /public/publications` and `/<id>` query publication identities, projection JSON blobs, and participant display rows on every request.
4. **Director results and report data:** `GET /contests/<id>/results` and `GET /contests/<id>/report-data` join 8–14 database tables and perform staleness checks on every call.
5. **Sync revision polling:** `GET /api/v1/sync/revision` opens a PostgreSQL transaction to run `SELECT MAX(sequence)` on repeated client polls.
6. **Authentication & authorization:** Every `/api/v1` request executes 2 queries in `AccountPrincipalResolver` (identity, account) and a third query in `requireContestDirector` (contest ownership).

Introducing an ephemeral Redis cache and volatile throttle eliminates database write contention and collapses CPU recalculation spikes while keeping the database as the sole durable source of truth.

### Operating behaviour (decided)

1. **Pure warm cache:** Redis is strictly an ephemeral acceleration layer. Every code path falls back to PostgreSQL on a cache miss or if Redis is unreachable.
2. **Zero durable state / no migrations:** Redis holds no state that is not in PostgreSQL or transient (short-lived rate counters). A restart, flush, or container upgrade causes no data loss and requires no schema migrations.
3. **Provider portability:** The client uses standard Redis RESP protocol over standard `redis://` or `rediss://` URLs, allowing switching between self-hosted Fly.io Redis, Upstash, Redis Cloud, or AWS ElastiCache by setting an environment variable.
4. **Offline and test isolation:** The embedded Windows instance and test suites run with `NullCacheStore` and never attempt a Redis connection.
5. **Short-lived invalidation:** Results and public caches use short TTLs (5–60s) combined with event-driven invalidation on score submissions, recalculations, and publication state changes.

---

## Sub-issues and Scope

### 1. Redis client foundation, configuration, and server wiring ([#943](https://github.com/mikejr83/rc-soar-score/issues/943))

- **Package dependency:** Add standard Redis client (`package:redis`) to `packages/soar_score_core/pubspec.yaml`.
- **Cache abstraction (`soar_score_core`):**
  - `abstract interface class CacheStore` with `get`, `set` (optional TTL), `delete`, `increment`, `expire`, `exists`.
  - `RedisCacheStore implements CacheStore`: connects via `REDIS_URL`, logs warnings on connection errors, and returns fallback miss values (`null`, `0`, `false`).
  - `NullCacheStore implements CacheStore`: no-op store used by embedded instance and tests.
- **Server configuration (`soar_score_server`):**
  - Add optional `REDIS_URL` to `ServerConfig.environmentKeys`.
  - Parse and validate scheme; include in `describe()` with masked password.
- **Server lifecycle:**
  - Connect `RedisCacheStore` during server startup; close in `RunningServer.close()`.
  - Pass `CacheStore` into `createServerHandler` and `buildApiHandler`.
- **Health check:** Add `cache: "ok" | "unavailable"` to `GET /health` payload without failing overall health.
- **Deployment:** Provide Fly.io `fly.toml` for self-hosted `redis:7-alpine` (256 MB RAM, `--save ""` `--appendonly no` `--maxmemory 180mb` `--maxmemory-policy allkeys-lru`).

### 2. Invitation throttle: Redis `RequestThrottleStore` ([#944](https://github.com/mikejr83/rc-soar-score/issues/944))

- **Store implementation:** `RedisThrottleStore implements RequestThrottleStore` in `soar_score_core`.
- **Hit counter:** `throttle:{bucket}:{caller}` with atomic `increment`. Sets TTL to window length on the first hit.
- **Read & purge:** Reads parsed count and window start; purge is a no-op as Redis handles expiration automatically.
- **Graceful fallback:** Falls back to `InvitationThrottle`'s in-memory `FailureRateLimiter` on Redis error.
- **Wiring:** `createServerHandler` supplies `RedisThrottleStore` when `REDIS_URL` is set, preserving `RequestThrottleStore(database)` as the fallback.

### 3. Preliminary results cache for self-scoring reads ([#945](https://github.com/mikejr83/rc-soar-score/issues/945))

- **Cache layer:** `PreliminaryResultsCache` in `soar_score_core` caching `PreliminaryCalculation` output under `contest:{contestId}:preliminary`.
- **TTL & recalculation:** 5-second TTL collapses concurrent reads from pilots on the flight line.
- **Invalidation:** Immediate eviction on `POST /rounds/{round}/scores` (self-scoring attempts) and `POST /contests/{id}/scores/*` (official score writes).
- **Service injection:** Injected into `PreliminaryResultsService.calculate()`; shared instance reused across `participant_results_views.dart`.

### 4. Public publication reads cache ([#946](https://github.com/mikejr83/rc-soar-score/issues/946))

- **Cache keys:**
  - `pub:detail:{id}` (detail endpoint, 30s TTL).
  - `pub:list:{sha256(sortedQuery)}` (listing endpoint, 30s TTL).
- **Handler wrapping:** Checks Redis before invoking `PublicPublicationService`. Returns cached JSON response on hit.
- **Event-driven invalidation:** Evicts publication detail and list cache entries on `POST /contests/{id}/publication`, `PATCH .../visibility`, and `POST .../delist-requests`.
- **Error exclusion:** Never caches error responses (404, 403).

### 5. Director results and report-data cache ([#947](https://github.com/mikejr83/rc-soar-score/issues/947))

- **Cache keys:**
  - Standings: `contest:{id}:results:asOf:{round}` (60s TTL).
  - Round flights: `contest:{id}:round:{ordinal}` (60s TTL).
  - Report data: `contest:{id}:report-data:{sha256(query)}` (30s TTL).
- **Invalidation:** Clear all result and report keys for `{id}` on `POST /contests/{id}/results/recalculation`, score writes, and matrix/configuration changes.

### 6. Sync revision polling cache ([#948](https://github.com/mikejr83/rc-soar-score/issues/948))

- **Atomic sequence counters:**
  - Contest scope: `sync:revision:contest:{contestId}`.
  - Account scope: `sync:revision:account:{accountId}`.
- **Exchange hook:** Update counter atomically after mutations are accepted in `POST /sync/exchange`.
- **Revision poll hook:** `GET /sync/revision` reads the Redis counter first; falls back to `acceptor.revision()` transaction on miss. Authorization continues to verify director ownership via database.

### 7. Auth principal and contest-owner cache ([#949](https://github.com/mikejr83/rc-soar-score/issues/949))

- **Principal resolution:** `auth:principal:{issuer}:{subject}` -> `{accountId, canSignIn}` (5-minute TTL).
- **Contest ownership:** `contest:{id}:owner` -> `ownerAccountId` (10-minute TTL).
- **Guest session:** `session:guest:{sha256(sessionToken)}` -> `ParticipantAccess` DTO (2-minute TTL).
- **Security:** Opaque or hashed keys, short expirations to respect account archival and session revocation.

---

## Acceptance Criteria

- [ ] All cache operations fall back gracefully to PostgreSQL on Redis absence or failure.
- [ ] No PostgreSQL writes occur during invitation resolves when Redis is available.
- [ ] Concurrent self-scoring reads within 5s do not re-execute scoring engine calculations.
- [ ] Score writes and recalculations immediately invalidate affected preliminary and official results.
- [ ] The embedded Windows instance runs without any Redis dependency.
- [ ] Switching Redis providers requires only changing the `REDIS_URL` environment variable.
