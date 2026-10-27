---
target: the public site home page
total_score: 25
max_score: 36
na_heuristics: 9
p0_count: 2
p1_count: 2
target_identity: "file:C:\\Users\\mason\\Projects\\rc-soar-score\\apps\\soar_score_web\\src\\app\\page.tsx"
target_fingerprint: 'sha256:435a4e8e698df248da92cfc270746dcb30b89b239ea220a6c5109652b6a94327'
target_path: "C:\\Users\\mason\\Projects\\rc-soar-score\\apps\\soar_score_web\\src\\app\\page.tsx"
timestamp: 2026-10-27T13-41-05Z
slug: apps-soar-score-web-src-app-page-tsx
closed: true
---

Method: dual-agent (A: critique-a · B: critique-b)

## Design Health Score (Persuade surface; H9 n/a)

| #         | Heuristic                       | Score     | Key Issue                                                                        |
| --------- | ------------------------------- | --------- | -------------------------------------------------------------------------------- |
| 1         | Visibility of System Status     | 2         | Dial readout "10:00" contradicts its 62% sweep; dropped round shows no mark      |
| 2         | Match System / Real World       | 3         | Sport vocabulary throughout; "Login" and "the service" are not                   |
| 3         | User Control and Freedom        | 3         | External hosts open with no cue                                                  |
| 4         | Consistency and Standards       | 2         | Orange CTA is Find at top, Run at bottom; 36px station buttons vs 44px elsewhere |
| 5         | Error Prevention                | 2         | No warning before the unsigned alpha download or the sample-data score app       |
| 6         | Recognition Rather Than Recall  | 3         | Role labels on every card; numbered eyebrows                                     |
| 7         | Flexibility and Efficiency      | 3         | Skip link, phone Contests shortcut, native details menu                          |
| 8         | Aesthetic and Minimalist Design | 3         | Strong idiom; 14 buttons page-wide, two oranges in the hero                      |
| 9         | Error Recovery                  | n/a       | Static page, no inputs                                                           |
| 10        | Help and Documentation          | 4         | Role-targeted guides and support before the visitor asks                         |
| **Total** |                                 | **25/36** | **Good (69%)**                                                                   |

## Design Specificity Verdict

**LLM assessment:** Authored, not interchangeable. The working-time dial, the CD/PLT/PUB bezels, the flight-plan route and a score anatomy built on the real F5J formula all belong to this sport. The scaffolding around them (three-card grid, 2x2 help cards, centred three-button close) is stock. The cracks are where a domain user looks: the dial readout disagrees with its sweep, and the "dropped" round is neither marked nor excluded from the total.

**Deterministic scan:** source scan clean (0 findings). Browser scan: 3 elements, 6 findings: pulsing-dot (error) on the hero scroll hint; hero-eyebrow-chip above the h1; thin border + 40px shadow on the mobile menu sheet; shape-assembled SVG (the dial, 71 primitives, no aria-hidden or title); repeating stripes on a score-anatomy bar segment; two-axis grid "seams" background on the hero, flight-plan and closing sections. False positives: the dial (an instrument drawn from ticks) and the bar hatch (a measurement surface). The seams grid is a real hit: section decoration, not an instrument. The detector caught the dial's missing aria-hidden, which the review missed.

## Overall Impression

A page with a real point of view and the domain fluency to back it, undercut by arithmetic a pilot can check, copy that claims more than the alpha ships, and a first viewport with seven actions. Biggest opportunity: make the hero one honest decision and let the dial and the anatomy carry the proof.

## What's Working

- **The working-time dial** (`working-time-dial.tsx`): drawn from the palette, one orange, animates once, respects reduced motion.
- **The score anatomy** (`score-anatomy.tsx`): real components, a correct 0.5 pt/m penalty rate, bars that grow in, a link to the quick reference.
- **The help section** (`help-links.tsx`): a guide per seat plus support, answered before asked.

## Priority Issues

- **[P0] Dropped round is counted and unmarked.** `score-anatomy.module.css` styles `.dropped .num` and `.part dt .num` inside a CSS module, so `.num` is hashed and never matches the global class the TSX applies (confirmed: no strike-through live). The total 3941.8 sums all four rounds. **Fix:** use `:global(.num)` (the dial module already does this for `.eyebrow`), set the total to 2987.4 and recheck "45.6 points behind 1st". **Command:** /impeccable harden
- **[P0] No "Draft, pending review (#165)" note.** Every other public page carries `DraftNote`; the homepage has none. **Fix:** add the shared note. **Command:** /impeccable clarify
- **[P1] Invisible keyboard focus on dark panels in light mode.** `--focus` maps to ink in light mode while the hero, flight plan and closing sections are always near-black. Derived from CSS. **Fix:** set `--focus: var(--panel-accent)` inside the dark panels. **Command:** /impeccable harden
- **[P1] Hero overclaims and overloads.** Three CTAs where PRODUCT.md names two equal ones; "Enter my score" points at an app on sample data; seven actions in the first viewport; two oranges in one area. **Fix:** two hero buttons; move Enter my score to the PLT card labelled invitation-only; make header Login a ghost. **Command:** /impeccable distill
- **[P2] Dial readout contradicts the sweep.** "10:00" with the sweep at 62% and the hand at 223°. **Fix:** readout 03:48 remaining or 06:12 elapsed, or start both at zero. **Command:** /impeccable polish
- **[P2] Phone loses both signature visuals.** Dial below the fold at 390px, flight-plan route display:none under 840px, station buttons 36px, small text 14px. **Fix:** compact dial in the phone hero, a vertical route on phone, drop `btn--sm`. **Command:** /impeccable adapt

## Persona Red Flags

**Jordan:** "draw the matrix", "man-on-man", "normalised", "F5J" never defined. "Run a contest" and "Login" both go to the app host. "Windows download" lands on GitHub releases with no word that it is an unsigned alpha.

**Riley:** the dropped-round arithmetic. Three external hosts with no cue. The dial drifts to 40% opacity under scroll-driven animation. Third station card reveals ~180 ms after its siblings on a direct scroll jump.

**Casey:** dark hero with 17px grey lede; three hero buttons over two rows with the third orphaned; dial out of view. Hit areas under 44px: header Login 36px, four station links 36px, inline F5J link 15px, six footer links 32px, Skip to content 41px.

## Minor Observations

- Facts label "Works" reads as a verb fragment.
- The eyebrow retypes the tagline beside a wordmark that already carries the orange RC.
- Closing lede promises "follow one that is on now" with no published contests.
- Footer legal line carries a design credit and a score-correction sentence with no link to Support.
- `.place::before` clips "YOUR PLACE AFTER ROUND 4" at some widths.
- Help lede orphans "does." on desktop.
- Dial SVG has no aria-hidden, role or title.
- Vercel Analytics logs each pageview twice in dev.

## Questions to Consider

- If the phone in sunlight is the first principle, why is the hero a near-black panel with its one visual below the fold on that phone?
- Find a contest is orange at the top and Run a contest at the bottom. Is "equal weight" a decision, or two sections that never met?
- With no published contests and an alpha build, would one honest line convert better than three CTAs?
