# Deploy the API server to Fly.io

The API runs on Fly.io with PostgreSQL on Neon, as decided in
[ADR 0003](adr/0003-hosting-platform.md). The monthly spend cap is $15. Normal
deploys are made by the Deploy workflow when a GitHub release is published; see
[deploying.md](deploying.md) for the release process, the hosts and the
secrets. This page covers the API specifically, including a manual deploy.

The server migrates the database when it starts, so an empty Neon database is
enough. No secret lives in the repository: `DATABASE_URL` is a Fly secret.

## Environment variables

| Variable                          | Where      | Value                                                                                                                                                         |
| --------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `DATABASE_URL`                    | Fly secret | Neon **direct** (not pooled) connection string; it ends in `sslmode=require`                                                                                  |
| `INVITATION_SECRET`               | Fly secret | 32+ random characters (`openssl rand -base64 48`); signs invitation links and guest sessions. Set it once: changing it ends every printed QR code and session |
| `AUTH0_DOMAIN`                    | `fly.toml` | `login.rcsoarscore.com` (the token issuer; not the `dev-...` tenant name)                                                                                     |
| `API_AUDIENCE`                    | `fly.toml` | `https://soar-score.com/server`                                                                                                                               |
| `CORS_ALLOWED_ORIGINS`            | `fly.toml` | app, score and public site origins                                                                                                                            |
| `PORT`, `LOG_LEVEL`, `LOG_FORMAT` | `fly.toml` | `8080`, `INFO`, `json`                                                                                                                                        |

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

A published GitHub release deploys the API through
`.github/workflows/deploy.yml`. Fly builds the image from
`apps/soar_score_server/Dockerfile` on its remote builder (there is no image in
GitHub Container Registry) and runs a single machine. To deploy by hand, from a
checkout of the tag:

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

## Idle behaviour

During alpha the machine stops when idle and starts on the next request, so
the first request after a quiet spell takes a few seconds (Neon's own wake-up
adds a little more). For the MVP release set `min_machines_running = 1` and
`auto_stop_machines = "off"` in `fly.toml`.

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
