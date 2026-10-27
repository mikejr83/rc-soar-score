---
target: the public site home page
total_score: 29
max_score: 36
na_heuristics: 9
p0_count: 0
p1_count: 1
target_identity: "file:C:\\Users\\mason\\Projects\\rc-soar-score\\apps\\soar_score_web\\src\\app\\page.tsx"
target_fingerprint: 'sha256:b7accd2639540f8c89bcf012e3ceb70a2b9af749efab156bc3a0f4e89a1944bc'
target_path: "C:\\Users\\mason\\Projects\\rc-soar-score\\apps\\soar_score_web\\src\\app\\page.tsx"
timestamp: 2026-10-27T17-43-40Z
slug: apps-soar-score-web-src-app-page-tsx
closed: true
---

Method: dual-agent (A: critique-a2 · B: critique-b2)

## Design Health Score (Persuade surface; H9 n/a)

| #         | Heuristic                       | Score     | Key Issue                                                                               |
| --------- | ------------------------------- | --------- | --------------------------------------------------------------------------------------- |
| 1         | Visibility of System Status     | 3         | Dial and external cues now agree; nothing says no contests are published yet            |
| 2         | Match System / Real World       | 4         | Field vocabulary throughout; the dial reads like the real instrument                    |
| 3         | User Control and Freedom        | 3         | App links leave the site in the same tab with no return path but the browser            |
| 4         | Consistency and Standards       | 3         | "Sign in", "Run a contest" and "Open the app" all go to one host; Docs vs Documentation |
| 5         | Error Prevention                | 3         | Alpha disclosed before the download; invitation-only is body copy, not the button       |
| 6         | Recognition Rather Than Recall  | 3         | Every card labelled by role; section numbers carry no navigation                        |
| 7         | Flexibility and Efficiency      | 3         | Skip link, sticky header, native details menu, Contests shortcut on phone               |
| 8         | Aesthetic and Minimalist Design | 3         | Orange budget respected; the draft note floats alone between hero and stations          |
| 9         | Error Recovery                  | n/a       | Static page, no inputs                                                                  |
| 10        | Help and Documentation          | 4         | A guide per seat plus support, before the visitor asks                                  |
| **Total** |                                 | **29/36** | **Good (81%)**                                                                          |

## Design Specificity Verdict

**LLM assessment:** Authored, not interchangeable. The working-time dial with a glider for a hand, the CD/PLT/PUB bezels, the route the glider rides on scroll (now on phones too), and a score anatomy built on the real F5J components all belong to this sport. It slips where the metaphor outruns the product: "built by people who fly" is unevidenced, and the pilot card links to a self-scoring app that still runs on sample data.

**Deterministic scan:** home page source clean (0 findings). Components tree: 3 findings in docs and support stylesheets, none on this page. Browser scan: 2 anti-patterns plus one advisory: the dial (drawn instrument, false positive), the hatched penalty bar (measurement fill, false positive), and the seams grid behind the three dark sections (accepted by the owner 2026-10-27 as the panel idiom).

## Overall Impression

The arithmetic is right, the hero is one honest decision, and the phone gets both signature visuals. What remains predates today's passes: the reveal animation hides most of the page without JavaScript, one app host wears three button labels, and the draft note sits in the worst possible place. Biggest opportunity: the no-js gap.

## What's Working

- **The working-time dial**: drawn from the palette, animates once, drifts out on scroll, leads the phone hero.
- **Honest platform claims**: "The web, or offline on Windows", "The Windows build is an alpha"; iOS and Android nowhere.
- **Score anatomy**: real units, hatched penalty, dropped round as strike-through plus hidden "(dropped)".

## Priority Issues

- **[P1] Reveal sections are blank without JavaScript.** `globals.css` starts every `[data-reveal]` at opacity 0, restored only by `data-inview` or `html.no-js`; nothing sets `no-js`. Breaches the AGENTS.md rule that content is never hidden behind an animation without JavaScript. **Fix:** add `no-js` to `<html>` in the root layout and strip it in a one-line inline script before paint. **Command:** /impeccable harden
- **[P2] Four buttons, one destination, three names.** "Sign in", "Run a contest" and "Open the app" all go to the contest app; "Sign in" implies an account the alpha lacks. **Fix:** one verb for the app in header, hero and CD card. **Command:** /impeccable clarify
- **[P2] The draft note is a hierarchy wart.** It renders alone in a band between hero and stations. **Fix:** move it into the hero facts row, a thin strip under the header, or the footer legal line; keep the text and #165. **Command:** /impeccable layout
- **[P3] "Find a contest" leads to nothing yet.** Zero published contests; the orange hero button lands in an empty search. **Fix:** make the contests page's empty state the pitch with a link to the director path, or a short note on the home page. **Command:** /impeccable onboard
- **[P3] Self-scoring promised before it ships.** "Enter my score" links to an app on sample data; "built by people who fly" is unsourced. Flagged for Mike. **Fix:** label the pilot card "coming"; cut or source the claim. **Command:** /impeccable distill

## Persona Red Flags

**Jordan:** Run a contest is the ghost button in the hero; then Sign in, Open the app and Windows alpha download with no guidance. Free and open source only in the last section.

**Riley:** ghost buttons are a 1px hairline on near-black that vanishes in sun. Find a contest lands in an empty list. 6460px tall on a 390px phone; help cards never reached.

**Casey:** desktop flight plan is five columns of 15px muted grey on charcoal. Footer design credit and personal names read as internal.

## Minor Observations

- "Best three of four rounds count" states a configured example as a rule.
- Header "Docs", footer "Documentation", help block "All documentation".
- "I Need An Account?" is the only title-case question card.
- Footer "Contest administration" wraps at 390px with the arrow on line two.
- Dial `drop-shadow` filter on an animated element is a paint cost on low-end phones.
- Only inline text links are under 44px; no console errors; no overflow at 390px.

## Questions to Consider

- If no contest is published for three months, what should the orange hero button do?
- Does the home page need to sell self-scoring before the API exists?
- Is the draft note part of the instrument panel, or a sticky note that belongs at the bottom of the checklist?
