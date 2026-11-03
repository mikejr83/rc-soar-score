# Public Site Agent Guide (`soar_score_web`)

The public web site: product marketing and information, documentation and help, support, and the published contest results. Next.js (App Router, TypeScript), no UI framework; plain CSS with the brand kit's tokens. See ADR 0005 (`docs/adr/0005-public-site-nextjs.md`).

## Commands

- `npm install` once, then `npm run dev` (http://localhost:3000), `npm run build`, `npm run lint`, `npm test` (vitest, `src/**/*.test.ts`).
- CI runs lint, test and build in the `public-site` job of `.github/workflows/ci.yml`. Melos does not manage this app.
- Deployed to Vercel by the Deploy workflow when a GitHub release is published (docs/deploying.md); the app is a standard Next.js build (no static export, the contest routes are dynamic). Hosts are set per deployment with `SOAR_SCORE_API_URL` (server-side proxy target for `/api/*`), `NEXT_PUBLIC_SOAR_SCORE_API_BASE_URL`, `NEXT_PUBLIC_CONTEST_APP_URL`, `NEXT_PUBLIC_SELF_SCORE_APP_URL` and `NEXT_PUBLIC_DOWNLOAD_URL` (`src/lib/site.ts` holds the ADR 0003 defaults).

## Structure (`src/`)

- `app/` — routes. `layout.tsx` (fonts, metadata, header and footer), `page.tsx` (homepage), `not-found.tsx`, `docs/*`, `support/`, `open-source/`, `results/contests/*`. `next.config.ts` holds the two redirects (`/results`, `/help`).
- `app/fonts.ts` and `fonts/` — the three brand fonts (OFL), copied from `packages/soar_score_ui/assets/fonts`. `public/brand/` — the logo SVGs from `packages/soar_score_ui/assets/logos`. Change them there first, then copy.
- `app/globals.css` — the kit colours as fixed names, the semantic tokens (light and the dark mapping, which is a guess for the product owner to override; `data-theme="light"` or `"dark"` on `<html>` overrides the OS scheme, set by `components/theme-toggle` and restored before paint by the inline script in `layout.tsx` from the `theme` key in localStorage), type helpers (`.eyebrow`, `.stencil`, `.num`), `.btn`, `.card`, `.panel`, `.pill`, form classes and the `[data-reveal]` scroll animation. Components add CSS modules beside themselves; do not add globals for one component.
- `components/` — `site-header`, `site-footer`, `theme-toggle`, `brand-logo` (`BrandMark`, `BrandLockup`), `reveal` (IntersectionObserver, sets `data-inview`), `home/*` (hero with the working-time instrument, stations, flight plan, score anatomy, help links, closing panel), `docs/*` (nav, prose, topic cards), `support/*` (the form), `results/*` (contest search, header, round selector, the three tables, not-found, not-visible, states).
- `lib/site.ts` — site name, external hosts and the primary navigation. `lib/results/` — the port of the Flutter results models: `publication.ts` (API shapes as served, snake_case), `api.ts` (fetch and `ApiHttpError`), `published-contest.ts` (standings, teams, flight groups as of a round), `contest-summary.ts`, `contest-filters.ts`, `contest-load.ts`, `format.ts`, `paths.ts`, with tests and `__fixtures__/fake-publication.ts`.

## Search and sharing (#679, #680)

- `app/robots.ts` and `app/sitemap.ts` serve `/robots.txt` and `/sitemap.xml`; add new static pages to the sitemap list. `siteUrl` in `lib/site.ts` (`NEXT_PUBLIC_SITE_URL`, default the apex) is the canonical origin; `next.config.ts` redirects `www.rcsoarscore.com` to it. The root layout sets `metadataBase`, a per-page canonical (`"./"`), Open Graph and Twitter tags with `public/brand/share-image.png` (1200x630, the dark lockup on night; regenerate from the lockup SVG if the brand changes).

## Open source licences (`/open-source`, #687)

- `src/app/open-source/page.tsx` renders `src/content/licences.json` through `components/open-source/open-source-view.tsx`; `lib/licences.ts` holds the types and helpers. The page has the anchors `#contest-app`, `#self-scoring`, `#server` and `#public-site`; the apps link to them, so keep the ids stable.
- The JSON is generated, never edited by hand: `scripts/generate-licences.sh` (or `.ps1`) from the repo root, after `dart pub get` and `npm ci`. Overrides for packages with missing metadata are in `scripts/licence-overrides.json`; vendored standard texts in `scripts/licence-texts/`.
- Staleness check: `src/lib/licences.test.ts` compares fingerprints of `pubspec.lock`, `package-lock.json` and the overrides with the ones stored in the JSON, so `npm test` (and CI) fails when a lockfile changed. Regenerate and commit the JSON in the same PR as the dependency change.
- Details, copyleft review and open actions: `docs/open-source-licences.md`.

## Rules

- **Read-only.** The site never writes contest data; it reads `GET /public/publications` and `GET /public/publications/{id}` only.
- **Brand.** One orange element per area of a screen; small text on orange uses deep orange (`--deep-orange`), the brand orange is for graphics and large headings. Never retype the wordmark; use the logo files (`BrandLockup compact` below about 120px, where the lockup's tagline line is unreadable; the full lockup in the footer). The panel tokens follow the theme; the header pins the night values and the dial stays black. Status is always text plus an icon, never colour alone.
- **Motion.** Every animation sits under `prefers-reduced-motion: no-preference` or is cancelled by the global reduce rule; scroll-driven CSS animations are wrapped in `@supports (animation-timeline: ...)` with a static fallback. Content is never hidden behind an animation without JavaScript.
- **Results behaviour** follows `plan/ui/public-site/*.md`. Rounds, ties (`2=`), dropped rounds, re-flights, the coming-Sunday rule, the 30-day summary and the not-visible re-check are the Flutter pages' rules; change them in `lib/results` with a test.
- Keep files small and single-purpose; one route per file, shared bits in `components/`.
- Page copy that is unreviewed carries the "Draft, pending review (#165)" note; keep it until Mike signs the content off.
