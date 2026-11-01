# Deploying

Nothing is deployed when `master` changes. Hosting changes only when a GitHub
release is published, and every release deploys, pre-releases included,
because the server and the clients must ship together. The
[Deploy workflow](../.github/workflows/deploy.yml) does the work.

## Release process

1. Push finished work to `master` as usual. Nothing goes live.
2. When you want users to get it, create a GitHub release with a new tag
   (for example `v0.1.0`) and publish it. Publishing a draft counts; saving a
   draft does not.
3. The Deploy workflow runs, in this order:
   1. **API:** Fly builds the image from the tag's Dockerfile and deploys one
      machine, then `scripts/hosted-smoke.sh` checks `/health` and that the
      API refuses an unauthenticated request. Later jobs wait for this.
   2. **Public site:** `vercel pull`, `vercel build --prod`, `vercel deploy
--prebuilt --prod`.
   3. **Contest app and self-scoring (Cloudflare):** after the API, in
      parallel with the site. Flutter 3.47.4 builds each app with
      `--dart-define=SOAR_SCORE_API_BASE_URL=https://api.rcsoarscore.com`, then
      `wrangler deploy --assets=apps/<app>/build/web` uploads it to the existing
      Workers: `soar-score-contest` (`app.`) and `rc-soar-score-self-score`
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

| Secret              | Used by     | How to get it                                                     |
| ------------------- | ----------- | ----------------------------------------------------------------- |
| `FLY_API_TOKEN`     | API         | `fly tokens create deploy --app rc-soar-score-api`                |
| `VERCEL_TOKEN`      | public site | Vercel > Account Settings > Tokens                                |
| `VERCEL_ORG_ID`     | public site | `vercel link` in the repository root, then `.vercel/project.json` |
| `VERCEL_PROJECT_ID` | public site | the same file                                                     |

| `CLOUDFLARE_API_TOKEN` | Flutter apps | Cloudflare > My Profile > API Tokens > template "Edit Cloudflare Workers" |
| `CLOUDFLARE_ACCOUNT_ID` | Flutter apps | Cloudflare dashboard > Workers & Pages (right sidebar) |

Do not commit `.vercel/`.

Environment variables on each host:

| Where  | Variable                  | Value                                                                                                                                                 |
| ------ | ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Vercel | `SOAR_SCORE_API_URL`      | `https://api.rcsoarscore.com` (production). Server-side only; the `/api/*` rewrite in `next.config.ts` proxies to it. Renamed from `RAILWAY_API_URL`. |
| Vercel | `NEXT_PUBLIC_*`           | optional overrides listed in `apps/soar_score_web/AGENTS.md`                                                                                          |
| Fly    | `DATABASE_URL` (secret)   | see [deploy-api-fly.md](deploy-api-fly.md)                                                                                                            |
| Fly    | everything else           | `apps/soar_score_server/fly.toml`                                                                                                                     |
| Build  | `SOAR_SCORE_API_BASE_URL` | `--dart-define` for both Flutter web apps: `https://api.rcsoarscore.com`                                                                              |

## One-time setup (move to release deploys)

Do these once, in this order, so there is no gap.

1. Create the `Production` environment and add the six secrets above to it.
2. Vercel project settings: Root Directory `apps/soar_score_web`; rename the
   `RAILWAY_API_URL` environment variable to `SOAR_SCORE_API_URL` (Production)
   at the same time you merge the PR that renames it in `next.config.ts`.
3. Publish a first release and watch the Deploy run succeed (or run the
   workflow by hand against a tag).
4. Then stop the automatic deploys:
   - Vercel > Project > Settings > Git > Disconnect the repository.
   - Cloudflare > Workers & Pages > `soar-score-contest` and
     `rc-soar-score-self-score` > Settings > Builds > disconnect the GitHub
     repository. The environment variable `SOAR_SCORE_API_BASE_URL` there is
     no longer used.
   - Fly has no Git integration; nothing to change.
