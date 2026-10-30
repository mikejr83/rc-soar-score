# Deploy the API server to Fly.io

The API runs on Fly.io with PostgreSQL on Neon, as decided in
[ADR 0003](adr/0003-hosting-platform.md). The monthly spend cap is $15. Deploys
are run by hand with `flyctl` (GitHub Actions is not used for this yet).

The server migrates the database when it starts, so an empty Neon database is
enough. No secret lives in the repository: `DATABASE_URL` is a Fly secret.

## Where everything lives

| Host name | What | Hosted on |
| --- | --- | --- |
| `rcsoarscore.com`, `www.rcsoarscore.com` | public project site | Vercel (proxied by Cloudflare) |
| `app.rcsoarscore.com` | contest management site | Cloudflare |
| `score.rcsoarscore.com` | participant self-scoring site | Cloudflare |
| `api.rcsoarscore.com` | API server (this document) | Fly.io |

DNS for all of them is managed in Cloudflare. The public site is hosted on
Vercel, a connected app on the repository that builds and deploys when `master`
is updated; Cloudflare proxies it. The two Flutter web apps use Cloudflare's
free Workers hosting; Cloudflare is connected to the GitHub account and builds
and deploys them on every push. Only the API is deployed by hand.

## Environment variables

| Variable | Where | Value |
| --- | --- | --- |
| `DATABASE_URL` | Fly secret | Neon **direct** (not pooled) connection string; it ends in `sslmode=require` |
| `AUTH0_DOMAIN` | `fly.toml` | `login.rcsoarscore.com` (the token issuer; not the `dev-...` tenant name) |
| `API_AUDIENCE` | `fly.toml` | `https://soar-score.com/server` |
| `CORS_ALLOWED_ORIGINS` | `fly.toml` | app, score and public site origins |
| `PORT`, `LOG_LEVEL`, `LOG_FORMAT` | `fly.toml` | `8080`, `INFO`, `json` |

The full list is in `apps/soar_score_server/lib/config/server_config.dart`.

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

From the repository root:

```sh
fly deploy --config apps/soar_score_server/fly.toml \
  --dockerfile apps/soar_score_server/Dockerfile .
```

Then check it:

```sh
fly logs --app rc-soar-score-api      # look for "Database open and migrated."
scripts/hosted-smoke.sh https://api.rcsoarscore.com          # bash
./scripts/hosted-smoke.ps1 -BaseUrl https://api.rcsoarscore.com  # PowerShell
```

## Idle behaviour

During alpha the machine stops when idle and starts on the next request, so
the first request after a quiet spell takes a few seconds (Neon's own wake-up
adds a little more). For the MVP release set `min_machines_running = 1` and
`auto_stop_machines = "off"` in `fly.toml`.

## Rollback

```sh
fly releases --app rc-soar-score-api
fly deploy --image <image of the earlier release> --config apps/soar_score_server/fly.toml
```

Schema changes are made in place in version 1 and the server migrates on start,
so a rollback across a schema change needs a Neon restore (point-in-time
history) as well. Check the release's schema changes first.

## Moving to another host

Take a `pg_dump` of the Neon database, restore it on the new PostgreSQL, set
`DATABASE_URL` on the new host, run the same image there, and point the `api`
DNS record at it.
