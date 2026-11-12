# Deploying

Nothing is deployed when `master` changes. Hosting changes only when a GitHub
release is published, and every release deploys, pre-releases included,
because the server and the clients must ship together. The
[Deploy workflow](../.github/workflows/deploy.yml) does the work.

## Release process

The full checklist (versions, release notes, rollback, hotfixes) is in
[Releasing](releasing.md); this page describes what the Deploy workflow does.

1. Push finished work to `master` as usual. Nothing goes live.
2. When you want users to get it, create a GitHub release with a new tag
   (for example `v0.1.0`) and publish it. Publishing a draft counts; saving a
   draft does not.
3. The Deploy workflow runs, in this order:
   1. **API:** Fly builds the image from the tag's Dockerfile and updates the
      app's machines (one always on, plus stopped burst machines), then
      `scripts/hosted-smoke.sh` checks `/health` and that the
      API refuses an unauthenticated request. Later jobs wait for this.
   2. **Public site:** `vercel pull`, `vercel build --prod`, `vercel deploy
--prebuilt --prod`.
   3. **Contest app and self-scoring (Cloudflare):** after the API, in
      parallel with the site. Flutter 3.47.4 builds each app with
      `--dart-define=SOAR_SCORE_API_BASE_URL=https://api.rcsoarscore.com`, then
      `wrangler deploy` uploads it (`--assets=apps/<app>/build/web`, or for the
      self-scoring app `--config apps/soar_score_self_score/wrangler.jsonc`, which
      adds the single-page-app fallback that invitation deep links need) to the existing
      Workers: `rc-soar-score-contest` (`app.`) and `rc-soar-score-self-score`
      (`score.`).
4. Watch the run under Actions > Deploy. A failed API job stops the rest.

The same publish also starts the Windows alpha build
(`.github/workflows/release-windows.yml`), which attaches the zip to the release
a few minutes later. Both workflows start from the one event, so the release
can be created entirely in the GitHub UI (new tag, "Pre-release" for alphas).

### Redeploy or roll back

Actions > Deploy > Run workflow, enter an earlier tag, and choose which targets
to run. The workflow checks out that tag, so what runs is what the tag held.
Database schema changes are not rolled back (see
[deploy-api-fly.md](deploy-api-fly.md#rollback)).

### Previews

There are none. Pull requests and master pushes build nothing on Vercel,
Cloudflare or Fly (their Git integrations are disconnected). CI still runs the
tests and builds. To look at a change, run it locally.

## Hosts

| Host name                                | What                          | Hosted on                      | Deployed by                    |
| ---------------------------------------- | ----------------------------- | ------------------------------ | ------------------------------ |
| `rcsoarscore.com`, `www.rcsoarscore.com` | public project site           | Vercel (proxied by Cloudflare) | Deploy workflow, `public-site` |
| `app.rcsoarscore.com`                    | contest management site       | Cloudflare                     | Deploy workflow, `flutter-web` |
| `score.rcsoarscore.com`                  | participant self-scoring site | Cloudflare                     | Deploy workflow, `flutter-web` |
| `api.rcsoarscore.com`                    | API server                    | Fly.io, database on Neon       | Deploy workflow, `api`         |

DNS for all of them is managed in Cloudflare. The API record stays unproxied
(grey cloud). The monthly spend cap is $15 (ADR 0003).

## Secrets and settings

GitHub environment secrets, stored in the `Production` environment (Settings >
Environments > Production > Environment secrets); every deploy job runs in that
environment. None are stored in the repository.

| Secret                  | Used by      | How to get it                                                             |
| ----------------------- | ------------ | ------------------------------------------------------------------------- |
| `FLY_API_TOKEN`         | API          | `fly tokens create deploy --app rc-soar-score-api`                        |
| `VERCEL_TOKEN`          | public site  | Vercel > Account Settings > Tokens                                        |
| `CLOUDFLARE_API_TOKEN`  | Flutter apps | Cloudflare > My Profile > API Tokens > template "Edit Cloudflare Workers" |
| `CLOUDFLARE_ACCOUNT_ID` | Flutter apps | Cloudflare dashboard > Workers & Pages (right sidebar)                    |

The Vercel IDs are identifiers, not credentials, so they are Environment
**variables** (the Variables tab of the same environment): `VERCEL_ORG_ID` (the
Vercel team ID, Team Settings > General) and `VERCEL_PROJECT_ID` (Project >
Settings > General). To get them locally, `vercel link` and read
`.vercel/project.json`.

Do not commit `.vercel/`.

Auth0 needs no secret in CI or on any host. Builds take the tenant domain and
client IDs as `--dart-define` values, and the server only needs `AUTH0_DOMAIN`
and `API_AUDIENCE`; it verifies tokens against the tenant's public keys. These
are identifiers, not credentials, and nothing uses machine-to-machine access, so
there is no client secret. Adding a machine-to-machine application would be the
trigger to revisit this and store its secret in the `Production` environment.

Environment variables on each host:

| Where  | Variable                  | Value                                                                                                                                                 |
| ------ | ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Vercel | `SOAR_SCORE_API_URL`      | `https://api.rcsoarscore.com` (production). Server-side only; `src/proxy.ts` forwards `/api/*` to it. Renamed from `RAILWAY_API_URL`. |
| Vercel | `TRUSTED_PROXY_SECRET`    | The same value as the Fly secret of that name; the proxy sends it with the visitor's address so the API's rate limits count visitors (deploy-api-fly.md, "Throttling invitation links"). |
| Vercel | `NEXT_PUBLIC_*`           | optional overrides listed in `apps/soar_score_web/AGENTS.md`                                                                                          |
| Fly    | `DATABASE_URL` (secret)   | see [deploy-api-fly.md](deploy-api-fly.md)                                                                                                            |
| Fly    | everything else           | `apps/soar_score_server/fly.toml`                                                                                                                     |
| Build  | `SOAR_SCORE_API_BASE_URL` | `--dart-define` for both Flutter web apps: `https://api.rcsoarscore.com`                                                                              |

## One-time setup (move to release deploys)

Do these once, in this order, so there is no gap.

1. Create the `Production` environment and add the four secrets above to it, and the two Vercel IDs as variables (below).
2. Vercel project settings: Root Directory `apps/soar_score_web`; rename the
   `RAILWAY_API_URL` environment variable to `SOAR_SCORE_API_URL` (Production)
   at the same time you merge the PR that renames it in `next.config.ts`.
3. Publish a first release and watch the Deploy run succeed (or run the
   workflow by hand against a tag).
4. Then stop the automatic deploys:
   - Vercel > Project > Settings > Git > Disconnect the repository.
   - Cloudflare > Workers & Pages > `rc-soar-score-contest` and
     `rc-soar-score-self-score` > Settings > Builds > disconnect the GitHub
     repository. The environment variable `SOAR_SCORE_API_BASE_URL` there is
     no longer used.
   - Fly has no Git integration; nothing to change.
