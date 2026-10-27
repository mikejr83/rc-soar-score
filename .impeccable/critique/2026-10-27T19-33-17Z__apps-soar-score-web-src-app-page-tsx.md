---
target: the public site home page
total_score: 28
max_score: 36
na_heuristics: 7
p0_count: 0
p1_count: 2
target_identity: "file:C:\\Users\\mason\\Projects\\rc-soar-score\\apps\\soar_score_web\\src\\app\\page.tsx"
target_fingerprint: 'sha256:762ed245c30d9e1cdca37d9eed4da8fcc4e13fd10bfee2d53fab2e00ca1c11f7'
target_path: "C:\\Users\\mason\\Projects\\rc-soar-score\\apps\\soar_score_web\\src\\app\\page.tsx"
timestamp: 2026-10-27T19-33-17Z
slug: apps-soar-score-web-src-app-page-tsx
closed: true
---

Method: dual-agent (A: critique-a3 · B: critique-b3)

## Design Health Score (Persuade surface; H7 n/a)

| #         | Heuristic                       | Score     | Key Issue                                                                                                           |
| --------- | ------------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------- |
| 1         | Visibility of System Status     | 3         | "Coming" is text plus icon. The Windows download's alpha, unsigned status is a sentence in card copy, not a status. |
| 2         | Match System / Real World       | 4         | Contest, matrix, round, group, landing table, working time used as pilots use them.                                 |
| 3         | User Control and Freedom        | 3         | External links marked and announced. Sticky 64px header eats a 390px phone viewport.                                |
| 4         | Consistency and Standards       | 2         | Hero makes Find a contest primary, closing panel makes Run a contest primary.                                       |
| 5         | Error Prevention                | 3         | "Enter my score" is a live external button under a "Coming" pill.                                                   |
| 6         | Recognition Rather Than Recall  | 3         | Station codes CD, PLT, PUB need the role label beside them.                                                         |
| 7         | Flexibility and Efficiency      | n/a       | Landing page; no repeat-use shortcuts to evaluate.                                                                  |
| 8         | Aesthetic and Minimalist Design | 3         | Dark mode: Stations and Help cards at near-zero contrast.                                                           |
| 9         | Error Recovery                  | 3         | Footer gives the correction path; nothing says what happens when a contest is not found.                            |
| 10        | Help and Documentation          | 4         | Section 04 maps a guide to each seat, ends with Request support and All documentation.                              |
| **Total** |                                 | **28/36** | **Good**                                                                                                            |

## Design Specificity Verdict

**LLM assessment.** Authored, not interchangeable: the working-time dial with a glider hand, stencil station codes, the dashed flight route with a glider, and a score anatomy that decomposes a real F5J flight. The only generic element is the four-card help grid.

**Deterministic scan.** Whole site: 4 findings, 1 on the home page (the accepted seams grid, `globals.css:488`). Off this page: side-tab border in `docs/docs.module.css:173` and `support/support-form.module.css:10`, grid figure box in `docs/docs.module.css:188`.

**Visual overlays.** Browser console: shape-assembled-illustration (the authored working-time dial, false positive), repeating-stripes-gradient (the penalty hatch data mark in `score-anatomy.module.css:57`, false positive), codex-grid-background (accepted exception). No slop finding on the home page.

## Overall Impression

The page has a point of view and keeps it. The five priority issues from the previous run are gone. What surfaced is a layer below: the dark theme (recorded in PRODUCT.md as a guess) flattens the cards that carry the page's argument, and the honesty fixes left one seam, a live button under a "Coming" label. Biggest opportunity: the dark mapping.

## What's Working

- **The working-time dial** is the product's idea rendered as an object; reads at 220px, tells a story without a caption, sets the palette.
- **The score anatomy** explains F5J in three lines and a place card; the struck-through dropped round with a hidden "(dropped)" label is "never colour alone" done properly.
- **Progressive enhancement is real.** With no-js set, zero reveal elements stay hidden; the count-up renders its final value server-side; focus rings are visible orange on dark panels.

## Priority Issues

- **[P1] Dark-mode cards vanish.** `--surface` #262422 on body #1c1b1a with `--line` #3a3735; Stations and Help cards barely separate from the page. **Why:** many visitors see the dark theme and the three-station structure is the page's argument. **Fix:** raise the dark `--surface` and `--line` tokens, or restore the shadow dark mode removes. **Command:** /impeccable colorize
- **[P1] Live button under "Coming".** Pilot card's "Enter my score" links to the self-scoring app while the bezel says Coming. **Why:** breaks "claim only what ships"; a pilot lands in an app on sample data. **Fix:** drop the button until #589 ships, keeping the invitation sentence, or render a disabled control with that reason. **Command:** /impeccable harden
- **[P2] Small fixed labels.** Eyebrows 12px, round labels 11px, hero facts labels 12px, "Example numbers" 12px, muted grey. **Why:** sunlight and sunglasses; the labels carry meaning. **Fix:** 13px floor, full-strength colour on the facts row labels. **Command:** /impeccable typeset
- **[P2] Primary CTA flips between hero and closing panel.** A deliberate mirror from the first critique that reads as disagreement. **Fix if wanted:** same order and emphasis in both, or two equal ghost buttons in the closing panel. **Command:** /impeccable clarify
- **[P3] Penalty bar uses bonus grammar.** Launch height "−59 pts" grows rightward at 38% like the positive bars. **Fix:** draw from the right edge, or as a subtraction line under the two bars. **Command:** /impeccable clarify

## Persona Red Flags

- **Result-seeking pilot, desktop:** the strongest button lands on an empty contest list; the contests page carries the pitch but the home page does not warn.
- **Low-vision visitor:** 11 to 12px muted labels; ghost buttons on dark panels have faint #3a3735 edges.
- **Keyboard user:** passes (skip link, visible focus, announced external links, native details menu).
- **Contest director at the field on a phone:** sticky header plus 390px pushes both CTAs below the fold; "Windows alpha download" cannot be acted on from a phone; dark panels are the default regardless of theme.

## Minor Observations

- Hero facts row mixes product facts with a process note ("Copy: Draft, pending review").
- Place card's decorative circle crops at the top right at some widths.
- Footer legal line puts a design credit beside the score correction path.
- Flight plan phone glider overlaps the last waypoint at the bottom of the track.
- Five flight-plan legs and six help choices exceed the four-per-group rule; cognitive load 3 of 8 failures.

## Questions to Consider

- If Find a contest and Run a contest carry equal weight, why does either get the orange?
- Should the home page say "no contests published yet" before the primary button sends someone to find out?
- Should the light sections feel like daylight on a flying field, or is the cockpit the whole brand?
