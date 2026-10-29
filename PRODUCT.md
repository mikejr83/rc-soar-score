# Product

<!-- impeccable:product-schema 1 -->

Product context for the RC Soar Score suite. Written 2026-10-27 from the repository and one interview round with Mason (product owner's collaborator; Mike is the product owner). The public site in `apps/soar_score_web` is one surface of this product; the contest administration app and the participant self-scoring app share this record.

## Platform

web

## Users

- **Contest directors** running RC sailplane soaring contests: creating the contest, configuring rules, inviting pilots, drawing the matrix, entering or reviewing scores, publishing results. Often at a flying field with no or weak internet.
- **Pilots and helpers** at the field, on a phone, outdoors in bright sun, between flights: entering their own flight (time, landing, launch height), checking "where am I after round 4?" and "who is in my group next?".
- **Public viewers** (pilots, families, club officers, the curious) at home on desktop or tablet, finding a contest and reading full standings.

The public site's homepage serves **directors and result-seeking pilots equally** (confirmed 2026-10-27): "Find a contest" and "Run a contest" carry equal weight.

## Product Purpose

A scoring and management suite for radio-controlled sailplane soaring contests: create and configure a contest, draw the flight matrix, score every flight (by the director or by the pilots themselves), and publish standings round by round on a public site that anyone can open without an account. Success is a contest day that runs on the software from first draw to published final placings, with pilots able to see their standing on their phones between rounds.

## Positioning

**No Windows PC required.** The contest app runs in the browser or natively on Windows, iOS and Android devices (confirmed by the owner 2026-10-27). The incumbent tool directors compare it with is GliderScore (`docs/alpha-readme.txt`). Supporting claims from the repository: offline-first at the field with later sync, pilot self-scoring from a phone, public results as of any round, open source (`https://github.com/mikejr83/rc-soar-score`).

## Operating Context

- Contests are run at flying fields, frequently without internet. A director may create the contest online, run the day offline, and sync the results later over a hotspot (`plan/application-plan.md`).
- Pilots may enter scores through an invitation link without an account; directors may publish without an account by confirming an email (`plan/business-requirements/accounts.md`).
- The suite is three applications on one API: the contest administration app (`app.` host), the participant self-scoring app (`score.` host) and the public site (root host, this Next.js app). Hosts are in `apps/soar_score_web/src/lib/site.ts`.
- The public site is **read-only**: marketing and information, docs and help, support, and the published results (`GET /public/publications`).
- Requirements live in `./plan`; the public site specs are `plan/ui/public-site/*.md`.

## Capabilities and Constraints

- **Disciplines.** F5J is the only official discipline today. Confirmed 2026-10-27 as coming, recorded exactly as the owner typed them: `F3J* F3K** F3L*** F3B*** F3Q*** F3F* TD* ALES* F5L`. The meaning of the asterisks is unconfirmed (possibly priority tiers). The owner said Mike may have missed others; confirm any additions with Mike rather than adding from the FAI catalogue. The README's "Supported Soaring Disciplines" table lists six disciplines as supported; for public copy, treat F5J as official and the rest as coming.
- **Platforms shipped.** As of 2026-10-27 the repository ships the contest app for web and as a Windows download (`apps/soar_score_contest` has `web/` and `windows/` targets; `docs/windows-installer-requirements.md`; the download URL points at GitHub releases). iOS and Android native builds are part of the confirmed positioning but are not evidenced in the repository yet; public copy must not state them as available until they ship.
- **Stage.** Alpha. The Windows build is unsigned and has no account or sign-in (`docs/alpha-readme.txt`). Hosting of the public site is undecided (ADR 0005).
- **Terminology.** Contest, contest director, pilot, pilot class, round, group, matrix (the draw), re-flight, dropped round, penalty, landing table, working time. Definitions in `plan/application-plan.md`.
- **Results rules.** Tied places (`2=`), dropped rounds, re-flights, the coming-Sunday rule, the 30-day summary and the 15-minute not-visible re-check are settled behaviour in `apps/soar_score_web/src/lib/results`; design to them, do not redesign them.

## Brand Commitments

- Name: **RC Soar Score**. Published by **Laminar Stack**. Tagline in code: "RC glider contest scoring" (`src/lib/site.ts`).
- Brand kit: `packages/soar_score_ui` (fonts in `assets/fonts`, logos in `assets/logos`, theme in `lib/theme/`); the public site copies the fonts to `src/app/fonts/` and the logos to `public/brand/`. Change them in the kit first.
- Rules from `apps/soar_score_web/AGENTS.md`: one orange element per area of a screen; small text on orange uses deep orange; never retype the wordmark, use the logo files; status is always text plus an icon, never colour alone.
- `plan/ui/public-site/briefs/public-site.md` predates the kit (it says no logo exists and names the old blue/green Material palette); the kit supersedes it.

## Evidence on Hand

- Real contest data: **none** on the public site yet. No published contests, no contest counts, no pilot counts.
- Testimonials, customers, press: **none**. Do not fabricate.
- Demo data exists for development (`packages/soar_score_data/lib/seeding/demo/`) and a results fixture (`src/lib/results/__fixtures__/fake-publication.ts`); neither is public proof.
- All public site page copy is draft pending review in #165 and must carry the "Draft, pending review" note until Mike signs it off.
- Assets: logo SVGs (`public/brand/`), three OFL brand fonts, the discipline rule documents in `plan/business-requirements/disciplines/`.

## Product Principles

1. **Works at the field first.** No signal, bright sun, one hand, a laptop or a phone; everything else follows from that.
2. **One contest, three screens.** Director, pilot and public each get the view for their job on the same data; nobody copies numbers twice.
3. **Public results are the record.** Standings as of any round, linkable, correct as rounds are published, no account needed.
4. **Claim only what ships.** F5J official, other disciplines coming, no proof that does not exist.
5. **Any device.** The director is not tied to a Windows PC.

## Accessibility & Inclusion

- Field use: phone in direct sunlight with sunglasses, one-handed, weak mobile signal. High contrast and large touch targets are requirements, not polish.
- Never colour alone for state (in progress, completed, tie, dropped round, re-flight, penalty): text or icon as well.
- Full keyboard access with visible focus; sensible screen-reader order in results tables.
- Every animation respects `prefers-reduced-motion`; content is never hidden behind an animation without JavaScript (`apps/soar_score_web/AGENTS.md`).
