# ADR 0003: Managed hosting for release 1

- Status: accepted
- Date: 2026-10-06
- Decision issue: #74

## Context

Release 1 must be cheap to run and easy to move to a bigger platform later. The applications are three static Flutter web builds and one containerized Dart/shelf API with PostgreSQL. Azure is too expensive for release 1.

## Decision

Use a managed host for the first release:

- The Flutter web apps run on Cloudflare's free Workers hosting. Cloudflare is connected to the GitHub account and builds and deploys on every push, so no deploy workflow in this repository is needed for them.
- Cloudflare manages DNS for `rcsoarscore.com`.
- The API container runs on Fly.io (chosen 2026-10-30, [#130](https://github.com/mikejr83/rc-soar-score/issues/130)); see [deploy-api-fly.md](../deploy-api-fly.md).
- PostgreSQL runs on Neon's free tier to start.
- The domain uses the root for the public site, with `app.`, `score.` and `api.` subdomains:
  - `rcsoarscore.com` and `www.rcsoarscore.com`: public project site
  - `app.rcsoarscore.com`: contest management site (admin web app)
  - `score.rcsoarscore.com`: participant self-scoring site
  - `api.rcsoarscore.com`: API server (Fly.io)

## Portability rules

- The server reads all configuration from environment variables, including the database URL and the Auth0 issuer and audience.
- One Docker image is built in CI and pushed to GitHub Container Registry. Any host pulls that image.
- Only stock PostgreSQL features are used.
- The applications take their API base URL at build or startup.
- A runbook documents moving hosts: restore a `pg_dump`, then point DNS.
- A monthly budget alert is set on whichever provider bills.

## Consequences

- Expected cost is about $0 while testing and about $5 to $15 per month once real contests run. Prices come from third-party summaries and must be confirmed on each vendor's page before signing up.
- A scale-to-zero database can add a second or two to the first request after idle. This matters during a live contest.
- A single VPS running Docker Compose (API, PostgreSQL, Caddy) is the fixed-price fallback. No trigger for switching was decided; revisit if the bill passes about $10 or cold starts hurt a live contest.
- The monthly spend cap for release 1 is $15 per month (decided 2026-10-06, [#74](https://github.com/mikejr83/rc-soar-score/issues/74)). A budget alert at that amount is set on whichever provider bills. A bill above the cap is the signal to revisit the host or move to the single-VPS fallback.
