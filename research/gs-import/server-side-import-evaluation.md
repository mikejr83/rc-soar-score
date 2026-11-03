# Server-side GliderScore import: evaluation (2026-11-03)

Evaluation only. No code changed, no tickets filed. Timing (Mike, 2026-11-03): implement after the entire native import flow is finished, post alpha; this is parked research until then. Status: Mike agreed (2026-11-03) to a separate importer app on its own hostname, `import.rcsoarscore.com`. Related: epic #564, #577 (hosted/web decision, M5), Phase A (PR #707), Phase B drafts, periodic-worker analysis (2026-11-03).

## Recommendation in one paragraph

Add a small, separate Fly app, the **importer**, that does one job: take an uploaded `.mdb`, run the Linux `mdbtools` over it, and return the same table snapshot (`GliderScoreImportResult` JSON) the native app already gets from its embedded server. It has no database, no secrets, and scales to zero. The web client uploads straight to it (the API is not in the data path), then runs the existing pure-Dart mapper, matcher and review flow, and saves through the normal API. This keeps untrusted-file parsing and the CPU work off the API server, adds no new provider, and costs close to nothing while idle. The one real gap is on the save side: the web build has no local participant store today, so Phase A/B persistence needs a server-side or API-backed implementation (section 6).

## 1. Reading .mdb on Linux

- Today: `tools/gs_importer/` vendors Windows 32-bit `mdb-json.exe` and `mdb-tables.exe` (lsgunth fork of mdbtools, pinned commit). `GliderScoreImportProcessRunner` (soar_score_data) spawns them with `Process.run`, hardcodes the `.exe` names, buffers all stdout, and parses one JSON object per line. Nulls are omitted keys; binary columns are `{"$binary":...}`.
- Linux: upstream mdbtools is a normal Linux package (`apt install mdbtools`, already used in cloud sessions for Phase A fixtures). Same CLI (`mdb-tables`, `mdb-json -T "%Y-%m-%dT%H:%M:%S"`). No Access driver is needed; mdbtools parses the Jet file format directly. There is no usable pure-Dart parser, so a child process remains the approach.
- To close with a test, not assumption: the Linux build may differ from the pinned Windows fork, so date format, null omission, `$binary` shape and text encoding must be checked against the committed Phase A fixture and the reference file. Add a parity test comparing snapshots. Pin the Linux version in the importer Dockerfile (build a tagged mdbtools release rather than whatever apt serves).
- Code change: the runner needs a Linux variant (executable names without `.exe`, helper on PATH or an env var). `GS_IMPORTER_DIR` already exists as an override. The runner interface is path-based (`dbPath`), which fits: the importer writes the upload to a temp file, runs the service, deletes it.
- Licence: mdbtools is GPL; it stays a separate process we do not link, same posture as the Windows bundle. An image shipping the binary carries the source offer via the distro package or our NOTICE.
- Image: the API's runtime stage is `FROM scratch`. The importer needs a small distro base (debian-slim) for libc and mdbtools. That is another reason it should not be the API image.

## 2. Handing the work off the API server

Options on Fly only:

| Option | How it works | Pros | Cons |
| --- | --- | --- | --- |
| **A. Separate importer app (recommended)** | A second Fly app (`rc-soar-score-importer`), HTTP service, auto-stop, `min_machines_running = 0`. Client uploads to it directly. | API never touches the file; own image with mdbtools; own memory size; no DB secret so a parser exploit reaches nothing valuable; Fly auto-starts it on request. | One more deploy target in `deploy.yml`; validates Auth0 JWTs itself (needs only the public domain and audience); a few seconds of cold start on first upload. |
| B. API starts a Fly Machine per import | API calls the Fly Machines API to run a one-off machine with the importer image. | Strongest per-upload isolation; machine exits when done. | API needs a Fly API token (new high-value secret); the file must reach the machine (object storage such as Tigris, or stdin); needs job state and polling; much more code. |
| C. Queue plus worker | API enqueues in Postgres, a worker polls. | Handles long jobs. | A polling worker is what you want to avoid; overkill for small files. |
| D. Child process inside the API | `Process.run` in the API. | Least work. | The parser shares a container with `DATABASE_URL`; a same-user child can read the parent's environment and memory, so a memory-safety bug in mdbtools exposes the database. Adds memory pressure on a 256 MB machine. Rejected. |

Why A is enough: the work is short and bounded (reference file 2.1 MB, about 6,500 score rows; mdbtools reads a table in well under a second, so a whole snapshot is seconds). It is user-initiated and request-shaped, not timer or background work, so it does not conflict with keeping timers out of the API. If hosted import later needs heavy or long work (Phase D scores over a big file), option B is the upgrade, and the importer image is reusable unchanged.

Flow with A:
1. The web app picks the file (the browser gives bytes) and sends `POST` to the importer host with the Auth0 bearer token; body is the raw file (optionally gzip, since Access files compress well).
2. The importer validates, reads the requested tables, returns `GliderScoreImportResult` JSON plus a SHA-256 of the file, deletes the temp file, retains nothing.
3. The client runs mapper, matcher and review (pure Dart in `soar_score_core`), then saves through the API.

The existing `POST /imports/gliderscore` takes a server-side `path`. It must stay unwired on the hosted API (it answers 503 today). Never expose a path parameter on a hosted service; the hosted route takes bytes only.

## 2a. Hostname and scaling (agreed direction)

- Hostname: Fly's proxy routes by hostname to one app and cannot split paths of `api.rcsoarscore.com` across apps. The importer gets `import.rcsoarscore.com` (`fly certs add` on the importer app plus a CNAME in Cloudflare, as for the API). It needs `CORS_ALLOWED_ORIGINS` for `app.` and `score.` and validates Auth0 tokens with the same domain and audience. Path routing through a Cloudflare Worker was rejected (extra moving part, upload limits); proxying through the API was rejected (puts the upload back on the API).
- Scaling: Fly's proxy only starts and stops machines that already exist; it does not create new ones. Create two machines, both auto-stop, and set the service `hard_limit = 1` so each handles one import at a time and a second simultaneous import wakes the other machine. A third waits briefly or gets a retryable error. Verify against the current Fly concurrency and autostart docs when writing `fly.toml`.
- Browser uploads go straight to the importer; the API only sees the later save call.

## 3. Upload limits and untrusted-file security

mdbtools is C code parsing attacker-controlled bytes; assume it can crash or be exploited.

- Auth required (Auth0 token). Per-account rate limit; one concurrent import per machine, extras get 429.
- Size cap: proposal 25 MB uploaded (reference file is 2.1 MB), counted while streaming to disk, not trusted from `Content-Length`; 413 over the cap. If Cloudflare proxies the importer hostname, its plan upload limit (about 100 MB on free, to verify) is above this, so our cap governs. The API today has no body size limit (`readJsonBody` reads the whole body), another reason not to reuse it.
- Magic-bytes check (`Standard Jet DB` / `Standard ACE DB`) before running anything. No archive extraction on the server (no zip bombs). Gzip only as a transport encoding with a decompressed-size cap.
- Child process: argument list, never a shell; table names from an allow-list and never starting with `-`; wall-clock timeout (about 30 s) then kill; stdout byte cap plus the existing row cap (200,000 per table); non-root user, scrubbed environment, read-only root filesystem except a tmpfs for the upload, memory limit.
- No secrets and no database on the machine; outbound network not needed. A compromised parser finds nothing. This is the main reason for a separate app.
- Random temp file name, deleted in `finally`; the machine filesystem is ephemeral anyway.
- Return JSON only; never echo file bytes. Do not log file contents or pilot fields, only counts and error codes.
- Tests: truncated file, wrong extension, non-Access bytes, huge declared table, `.accdb` (unsupported, clear error).

## 4. Sync or async

Synchronous request/response. A typical import is seconds, inside Fly proxy timeouts; the client shows a progress state during upload. Cold start (a few seconds) is acceptable and can be hidden by pinging `/health` when the user opens the import dialog. Move to async (option B, job record, polling) only if a real file takes more than about 30 s.

Memory: size the importer at 512 MB (the API's 256 MB is tight) because the current runner buffers all stdout and the service captures whole tables. Better, stream stdout line by line (already on the Phase A follow-up list). Request only the tables each phase needs (`tables` parameter exists); `Scores` is the large one and Phases A and B do not need it.

## 5. Reuse of the core mapper and review flow

- Reusable as is, pure Dart in core: `GliderScoreImportService`, `GliderScoreImportResult` (JSON-serialisable and what the native wizard already receives over HTTP), the pilot mapper, matcher, `PilotImportService`, and Phase B's planned contest mapper. The server does not need the mapper.
- Web client work: the wizard is native-only today. `GliderScoreFiles` takes a path and reads through the embedded API; the web needs a bytes-based source and a new `ApiClient` upload method against the importer host. The review dialog is plain Flutter and should be reusable once the file source and store are abstracted.
- `web_closure_test` must keep passing: nothing in the web closure may import `dart:io` or `soar_score_data`.

## 6. Ownership and sync with local data (the real gap)

- Imported contests are owned by the signed-in account and sync like hand-made ones (Phase B decision D11). A web import appears in the native app after sync, and vice versa.
- `PilotImportStore` documents that the web build holds no local participants. Phase A/B persistence lives in `soar_score_data` against local SQLite, which the web cannot use. Two ways: (a) an API-backed store using existing participant endpoints, preserving the revision-check guard; (b) a new API endpoint that accepts reviewed selections and runs the persister on Postgres in one transaction (the API already uses `soar_score_data` on Postgres). I recommend (b): the multi-table contest creation, one transaction per competition and `import_provenance` rows would otherwise be many browser calls.
- The save endpoint takes reviewed drafts and decisions, not the file, so the API stays light. The draft is untrusted client input: re-validate ids, counts and sizes like any write.
- Provenance: the importer returns the file SHA-256, so the browser does not hash large files. Phases C and D filling the same contest are unaffected because they key on comp number plus fingerprint.
- Web import needs connectivity; native import stays available offline.

## 7. Privacy and retention of uploaded files

- The Pilots table holds names, emails, street addresses and phone numbers of other people, not only the uploader. The director is effectively controller of their roster and we process it for them; the privacy policy and retention plan need a line for this.
- The stateless design is the best answer: the file exists only as an ephemeral temp file for the request, is deleted at once, never goes to Neon or object storage, is never logged or backed up. Retention for uploaded files is zero and no sweep job is needed.
- The review snapshot goes back to the same user and is not stored. Only the director's saved result persists, under normal account data and deletion rules.
- If we ever store the original (re-import, support), it needs consent, a retention period, encryption at rest and a rule in the daily sweep (#640 to #643). Not recommended for the first version.
- Policy update: say uploaded GliderScore files are processed transiently and not kept. The importer is still Fly.io, so no new processor.

## 8. Cost

- Importer: shared-cpu-1x, 512 MB, scale to zero, one machine. Billed per second only while running; a few seconds per import is a fraction of a cent. Idle cost is little more than rootfs storage. Even always-on it would be a few dollars a month, inside the $15 cap, but scale to zero should be the default. (Prices quoted from memory; check current Fly pricing.)
- Bandwidth is negligible at 2 to 25 MB per upload.
- No Neon impact from the importer; the save endpoint adds normal write load.
- CI builds a second image per release. Engineering effort is the larger cost, not hosting.

## 9. Suggested phasing

Keep it behind #577 and after Phase B ships natively; Phase B is deciding the provenance and persistence contracts, and the hosted work should be a second implementation of them rather than a fork.

1. **H0 ADR (small).** Importer as a separate Fly app, stateless, size cap, no stored files, save through the API. Settles #577 as yes, in this way.
2. **H1 Linux reader (medium).** Linux runner variant, pinned mdbtools build, parity test against Windows output on existing fixtures, runner tests (timeouts, output caps, bad files). Also helps CI and cloud sessions.
3. **H2 Importer service (medium).** Dart app with Dockerfile, `fly.toml`, size/magic/rate/timeout controls, JWT validation, health check, deploy workflow step, runbook, security tests.
4. **H3 Web upload and review (medium to large).** Bytes-based file source, `ApiClient` upload, adapt the wizard to web.
5. **H4 Hosted save (large).** Persister contract in core, Postgres implementation, API endpoint for reviewed selections, provenance, SQLite and PostgreSQL tests. Pilots first (Phase A parity), then contests.
6. **H5 Docs and privacy.** User guide, privacy policy line, E2E step in the lifecycle journey (web mode runs in the cloud with the importer stubbed by a fixture).

H0 and H1 are cheap and can start before Phase B finishes. H3 and H4 wait for Phase B's persister contract. Milestone fits M5 per #577; earlier only if alpha testers need web import.

## 10. Open questions for Mike

1. Decided: separate importer app.
2. Hostname: decided, `import.rcsoarscore.com` (see 2a).
3. Upload cap 25 MB, gzip allowed from the client?
4. Decided: wait until the whole native flow is finished (post alpha).
5. Decided: not needed for the alpha; native is the only path until then.
6. Accept zero retention of uploaded files (re-import asks for the file again)?
7. Is a Linux mdbtools binary in the importer image fine under the current GPL approach?

## Not verified

- Linux mdbtools output parity with the Windows fork.
- Real time and memory on a large production-sized file; only the 2.1 MB reference file is available.
- Current Fly and Cloudflare limits and prices (from memory).
- Whether the web contest app has any API-backed participant store beyond what the pilot-import code comment says.
