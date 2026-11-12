# Deploy the API server to Fly.io

The API runs on Fly.io with PostgreSQL on Neon, as decided in
[ADR 0003](adr/0003-hosting-platform.md). The monthly spend cap is $15. Normal
deploys are made by the Deploy workflow when a GitHub release is published; see
[deploying.md](deploying.md) for the release process, the hosts and the
secrets. This page covers the API specifically, including a manual deploy.

The server migrates the database when it starts, so an empty Neon database is
enough. No secret lives in the repository: `DATABASE_URL` is a Fly secret.

## Environment variables

| Variable                          | Where                 | Value                                                                                                                                                         |
| --------------------------------- | --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `DATABASE_URL`                    | Fly secret            | Neon **direct** (not pooled) connection string; it ends in `sslmode=require`                                                                                  |
| `INVITATION_SECRET`               | Fly secret            | 32+ random characters (`openssl rand -base64 48`); signs invitation links and guest sessions. Set it once: changing it ends every printed QR code and session |
| `AUTH0_DOMAIN`                    | `fly.toml`            | `login.rcsoarscore.com` (the token issuer; not the `dev-...` tenant name)                                                                                     |
| `SELF_SCORING_BASE_URL`           | `fly.toml`            | not set in production, so invitation links point at `https://score.rcsoarscore.com`; only local runs override it                                              |
| `API_AUDIENCE`                    | `fly.toml`            | `https://soar-score.com/server`                                                                                                                               |
| `CORS_ALLOWED_ORIGINS`            | `fly.toml`            | app, score and public site origins                                                                                                                            |
| `PORT`, `LOG_LEVEL`, `LOG_FORMAT` | `fly.toml`            | `8080`, `INFO`, `json`                                                                                                                                        |
| `LOG_DB_STATEMENT_DURATIONS`      | Fly secret (optional) | off. `true` logs every database statement's duration while you measure (see [Measuring statement durations](#measuring-statement-durations))                  |

The full list is in `apps/soar_score_server/lib/config/server_config.dart`.

## Secrets and configuration catalog

Everything the API process reads, what the value must be, and what happens when
it changes. Only the two Fly secrets are confidential; the `fly.toml` values are
public identifiers and live in the repository.

### Fly secrets

List the names set on the app (values are never shown) and change them with
`fly secrets`. Setting or unsetting a secret restarts the machine.

```sh
fly secrets list --app rc-soar-score-api
fly secrets set NAME='value' --app rc-soar-score-api
```

| Secret              | Required | Value                                                                                                                                                                                                | If it changes                                                                                                                                                                              |
| ------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `DATABASE_URL`      | yes      | The Neon **direct** (not pooled) `postgresql://` connection string, with the password and `sslmode=require`. Remove `channel_binding=require` if Neon adds it: the driver rejects unknown parameters | Rotate the Neon role password in Neon, then set the new URL here. The server will not start without a working URL, so check `fly logs` for "Database open and migrated."                   |
| `INVITATION_SECRET` | no       | At least 32 characters, random. The server refuses a shorter one at start                                                                                                                            | Without it, the self-scoring routes answer 409 `invitations_not_available`. Changing it ends every guest session at once, and links already issued can no longer be reproduced (see below) |

Generate `INVITATION_SECRET` once and keep a copy somewhere safe (a password
manager), because the same value must stay in place for as long as printed QR
codes are in use:

```sh
# bash
fly secrets set INVITATION_SECRET="$(openssl rand -base64 48)" --app rc-soar-score-api
```

```powershell
# PowerShell
$bytes = New-Object byte[] 48
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$secret = [Convert]::ToBase64String($bytes)
fly secrets set "INVITATION_SECRET=$secret" --app rc-soar-score-api
```

Invitation links are derived from this secret and the invitation, so the
database holds only a hash of each link. After a change the stored invitations
remain, but the server cannot rebuild their links: the cards and invitation
lists report those pilots as having no usable link instead of serving a wrong
one, and sessions in pilots' browsers stop working. Regenerating links for
them is tracked in #791; until it exists, avoid rotating the secret once
cards are printed. A leaked secret is the one reason to rotate it.

To check that it is in effect, post any junk link; the answer is 404
`invalid_invitation`, not 409 `invitations_not_available`:

```sh
curl -s -X POST https://api.rcsoarscore.com/api/v1/self-scoring/invitations/resolve \
  -H 'content-type: application/json' -d '{"credential":"x"}'
```

Local runs use a fixed development secret from `.vscode/launch.json`, which is
public in this repository: never set it on the deployed app.

### Settings in `fly.toml`

| Variable                | Value                                                                                                                                                                    |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `AUTH0_DOMAIN`          | `login.rcsoarscore.com`, the custom domain that issues the tokens, with no scheme or path. Required                                                                      |
| `API_AUDIENCE`          | `https://soar-score.com/server`, the API identifier tokens must be issued for. Required                                                                                  |
| `CORS_ALLOWED_ORIGINS`  | Exact browser origins, comma separated, no trailing slash: the app, score and public site origins. The score origin must be here for the guest session cookie to be sent |
| `SELF_SCORING_BASE_URL` | Optional. The `https://` origin invitation links point at, no path. Defaults to `https://score.rcsoarscore.com`                                                          |
| `PORT`                  | `8080`, matching `internal_port`                                                                                                                                         |
| `LOG_LEVEL`             | `INFO`; any `package:logging` level name                                                                                                                                 |
| `LOG_FORMAT`            | `json` (or `text` for reading logs locally)                                                                                                                              |

The `POSTGRES_*` variables are the alternative to `DATABASE_URL` for local
databases and are not used on Fly.

### Measuring statement durations

To see what each database statement really costs from the Fly machine to Neon,
turn on the opt-in log. It is off unless you set the variable, and logging is
the only thing it changes.

```sh
fly secrets set LOG_DB_STATEMENT_DURATIONS=true -a rc-soar-score-api    # on (restarts the machine)
fly secrets unset LOG_DB_STATEMENT_DURATIONS -a rc-soar-score-api       # off again
```

(A secret is only the easy way to set a variable without a deploy; the value is
not confidential.)

Then read the lines with `fly logs -a rc-soar-score-api`. Each statement is one
line from the `db.statements` logger at INFO (so `LOG_LEVEL` must be `INFO` or
lower):

```
select 11.8ms args=2 SELECT "t"."id" AS "t.id", ... FROM "contests" "t" WHERE "t"."id" = $1 ...
```

Only the SQL text (cut at 200 characters, quoted literals blanked) and the
number of arguments are logged. Argument values, which can hold invitation
links, names and e-mail addresses, are never logged. The time is per statement
and can include waiting behind another statement on the single connection; time a
transaction waits to start is not measured. Remove the variable when done:
every statement adds a log line, which is noisy and costs a little CPU.

### Not read by the API

The deploy credentials (`FLY_API_TOKEN`, the Vercel and Cloudflare tokens) are
GitHub `Production` environment secrets used by the Deploy workflow, not by the
running server; they are listed in [deploying.md](deploying.md). Auth0 needs no
client secret anywhere.

## One-time setup

Check current prices on the Fly.io and Neon pricing pages first.

1. **Neon:** create a project in a region near Fly's `iad` (AWS us-east-1) with a
   database named `rc_soar_score`. Copy the direct connection string.
2. **Fly.io:** install `flyctl`, run `fly auth login`, add a card, and set a
   $15/month spending alert in the billing page.
3. From the repository root: `fly apps create rc-soar-score-api`
4. `fly secrets set DATABASE_URL='<neon url>' --app rc-soar-score-api`
5. Deploy (below).
6. **Domain:** `fly certs add api.rcsoarscore.com --app rc-soar-score-api`, then in
   Cloudflare add a CNAME `api` -> `rc-soar-score-api.fly.dev` with the proxy
   off (grey cloud). `fly certs show api.rcsoarscore.com` reports when the
   certificate is issued.

## Deploy

A published GitHub release deploys the API through
`.github/workflows/deploy.yml`. Fly builds the image from
`apps/soar_score_server/Dockerfile` on its remote builder (there is no image in
GitHub Container Registry) and updates the app's machines (one always-on
machine plus the stopped burst machines, see "Machines and bursts"). To deploy
by hand, from a checkout of the tag:

```sh
fly deploy --remote-only --ha=false \
  --config apps/soar_score_server/fly.toml \
  --dockerfile apps/soar_score_server/Dockerfile
```

Then check it:

```sh
fly logs --app rc-soar-score-api      # look for "Database open and migrated."
scripts/hosted-smoke.sh https://api.rcsoarscore.com          # bash
./scripts/hosted-smoke.ps1 -BaseUrl https://api.rcsoarscore.com  # PowerShell
```

### Hosted writes made before the sequence fix

A write the service makes itself (a pilot's submitted score, or any other
hosted API write) joins the contest's sync log as `Accepted` with the next
sequence. Rows written by an earlier version stay `Pending` with no sequence,
and installations never pull them; redeploying does not repair them. Have the
pilot resubmit, or delete the stuck entry and enter it again. There is no
backfill.

## Machines and bursts

The app runs one always-on machine (`shared-cpu-1x`, 512 MB, iad) and two more
of the same size that sit stopped until they are needed. `fly.toml` sets
`min_machines_running = 1`, `auto_start_machines = true`,
`auto_stop_machines = "stop"` and a concurrency soft limit of 10 requests (hard
limit 25). Fly's proxy starts a stopped machine when the running ones pass the
soft limit and stops it again when load falls, so no schedule is needed for a
contest weekend. A start takes a few seconds, which the always-on machine
covers. A stopped machine costs only its small root disk; a running one is
billed by the second.

Creating machines is an account change, so it is done by hand, once, after the
first deploy with this configuration:

```sh
fly machine list --app rc-soar-score-api          # note the existing machine id
fly machine clone <machine-id> --app rc-soar-score-api
fly machine clone <machine-id> --app rc-soar-score-api
fly machine stop <new-machine-id> --app rc-soar-score-api   # for each clone
```

(`fly machine clone` starts the new machine; stop each clone so it only runs
when Fly wakes it.) Clones inherit the image, size and settings, and a later
deploy updates them with the first machine. `--ha=false` only stops a first
deploy from creating spare machines; it does not remove existing ones. To
remove a burst machine: `fly machine destroy <machine-id> --force`.

Things to know:

- Every machine opens its own database connection to Neon, and the
  per-contest advisory lock keeps simultaneous writes safe across machines.
- Extra machines add CPU, not database speed: they share one Neon database
  and each runs statements one at a time. Region and batching still matter
  most (issue #846, epic #838).
- An in-memory cache, if added later, would be per machine.
- Neon's free plan suspends the database after 5 minutes idle; the first
  request after that waits for it to wake. Before a contest, load any API
  page a few minutes ahead.

## Public read cache policy

The `/public` reads are the only API responses meant to be cached (#906):

| Response                                                     | `Cache-Control`      |
| ------------------------------------------------------------ | -------------------- |
| `GET /public/publications` and `/public/publications/{id}`   | `public, max-age=30` |
| Any `/public` error (404 unknown, 403 `contest_not_visible`) | `no-store`           |
| `/api/v1/*` (signed-in data)                                 | `no-store`           |

For the next API read, a new publication, a delisting, or a change to hidden
results shows within **30 seconds** and no later. A results page that is
already open does not read again until it is reloaded or another contest is
opened (`ContestProvider` fetches once per contest id), so an open page can
keep showing what it loaded until the reader refreshes. The site's Refresh
button bypasses the browser cache for the listing. Errors are never cached, so
a contest that becomes visible shows at once.

The Next.js `/api` rewrite on the public site passes these headers through
unchanged (`proxy-config.test.ts` runs the real Next.js server against a stub
upstream and checks status, headers and body). Vercel's CDN ignores `max-age` and only caches on `s-maxage`, so the
browser is the only cache between a reader and the API.

An unknown id (404) and an id that exists but is not shown (403
`contest_not_visible`) are deliberately different answers (#463); the 403
body carries nothing about the contest.

## Rollback

```sh
fly releases --app rc-soar-score-api
fly deploy --remote-only --ha=false \
  --config apps/soar_score_server/fly.toml \
  --dockerfile apps/soar_score_server/Dockerfile   # from a checkout of the earlier tag
```

Or run the Deploy workflow by hand (Actions > Deploy > Run workflow) with the
earlier tag.

Schema changes are made in place in version 1 and the server migrates on start,
so a rollback across a schema change needs a Neon restore (point-in-time
history) as well. Check the release's schema changes first.

## Moving to another host

Take a `pg_dump` of the Neon database, restore it on the new PostgreSQL, set
`DATABASE_URL` on the new host, run the same image there, and point the `api`
DNS record at it.
