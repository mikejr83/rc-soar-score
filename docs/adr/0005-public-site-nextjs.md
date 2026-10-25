# ADR 0005: The public site is a Next.js app

- Status: accepted
- Date: 2026-10-23
- Decision issue: none (requested by Mason, 2026-10-23)

## Context

ADR 0003 describes the public site as one of three static Flutter web builds. The site is the product's front door: marketing and information, help for directors and pilots, links into the contest administration and self-scoring apps, and the published results. A Flutter web build is a poor fit for that: a large runtime before the first paint, no server-rendered HTML for search engines or link previews, and Material widgets where the brand kit wants editorial layout and motion.

## Decision

`apps/soar_score_public` (Flutter) is replaced by `apps/soar_score_web`, a Next.js (App Router, TypeScript) site that owns every public route: the homepage, `/docs/*`, `/support` and `/results/*`. It reads the same public API (`GET /public/publications`, `GET /public/publications/{id}`) from the browser; the results pages keep the Flutter pages' behaviour and routes. The brand kit's fonts and logos are copied into the app from `packages/soar_score_ui` so the site and the Flutter apps share one source.

Hosting is not decided here. The app is a standard Next.js build with no server-only features, so it runs on any Node host or on Vercel; a static export is not possible while the contest routes are dynamic. The contest and self-scoring apps stay Flutter.

## Consequences

- The repo has a Node toolchain beside Dart: CI runs `npm ci`, lint, test and build for the site in its own job; Melos does not see it.
- The public site no longer depends on `soar_score_api` or `soar_score_ui`; changes to the public projection must be mirrored in `apps/soar_score_web/src/lib/results/publication.ts`.
- ADR 0003's "three static Flutter web builds" is now two, plus this site.
