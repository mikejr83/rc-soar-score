# Ticket 026 — Matrix: Seeded Round Order (Leaders First vs. Last)

- **Category:** Matrix / Draw
- **Priority:** High
- **Status:** Ready
- **Decision:** In seeded man-on-man mode, leaders fly last. Group 1 contains the lowest-ranked tier; Group G contains the highest-ranked tier. The tier partition and team-protection swap are unchanged; fairness metrics are unaffected (the order flip is a relabeling of groups).

## Decisions

1. **Group ordering for seeded rounds (Q1): Leaders fly last.** In seeded rounds, the group that flies first (Group 1) contains the lowest-ranked tier of pilots (lowest cumulative scores), and the group that flies last (Group G) contains the highest-ranked tier (the leaders). Rationale: this matches the GliderScore convention and common man-on-man practice — the final round plays like a final, and the leaders fly in the same conditions everyone else flew earlier. This replaces `matrix-draw.md` §6.3 step 3's "assign the top-ranked tier of pilots to Group 1"; the spec must be corrected to the reversed mapping when the draw engine is implemented (per ticket 025, algorithm version `1.0.0`).

2. **Tier assignment reversal (Q2): yes, the tier-to-group mapping reverses.** The tier boundaries and group sizes are unchanged: `r = N mod G` groups have `b + 1` pilots and `G - r` groups have `b` pilots, where `b = floor(N / G)`. Under the reversed order, Groups `1..r` (the lowest-ranked groups) receive the extra pilot, and Group G's tier (the leaders) is whatever size the partition gives the final group. The partition of pilots into tiers is identical to what the current spec produces; only the tier→group label mapping is flipped (tier *k* from the top goes to Group `G - k + 1` instead of Group *k*) — equivalently, groups are relabel `k ↔ G - k + 1` against the existing spec.

3. **Team-protection swap (Q3): no change.** The minimal rank-displacement swap in `matrix-draw.md` §6.3 step 4 iterates groups 1..G, keeps the highest-ranked teammate in each group, and for each additional clash searches the *adjacent* groups (g_{k-1} or g_{k+1}) for the replacement minimizing the rank difference. That search is symmetric under a flipped group numbering: adjacency, rank values, and the minimization are all unchanged by the reversal. No new logic is needed. (Whether adjacent-only search can ever fail, and what fallback exists, is ticket 027's scope.)

4. **Effect on the fairness metric (Q4): none — perceived fairness only.** The composition of the groups is identical under either order: the reversal relabels group *k* as group `G - k + 1`, so the set of pilots in each group, and therefore every round's pairwise meeting counts, is exactly the same. The fairness report (matchup histogram, max duplicates, MAD, never-met pairs, lane uniformity) is byte-identical for the same standings input, and lane assignment (step 5) is per-group and history-based, so it is unaffected as well. What changes is only the temporal fly-off order — who flies first and last in each round — which is the perceived-fairness property this decision sets. The choice is also independent of the back-to-back constraint (ticket 028); if that constraint is added later, the leaders (last group, round r) are simply the pilots it excludes from the first group of round r + 1.

## Context

`matrix-draw.md` puts leaders in Group 1 (they fly first). GliderScore puts lowest scorers in Group 1 (leaders fly last). The research doc flags this as a direct contradiction requiring a deliberate decision.

## Questions

1. ~~In seeded man-on-man mode, should leaders fly first (Group 1) or last (Group G)?~~ — **Resolved: leaders fly last (Decision 1).**
2. ~~If leaders fly last, does the tier assignment reverse (rank N in Group 1, rank 1 in Group G)?~~ — **Resolved: yes — the tier→group mapping flips; tier sizes are unchanged (Decision 2).**
3. ~~How does the team-protection swap work with the reversed ordering?~~ — **Resolved: unchanged; the rank-displacement swap is symmetric under the reversal (Decision 3).**
4. ~~Does the choice affect the fairness metric (pairwise meeting counts) or only the perceived fairness?~~ — **Resolved: only perceived fairness; pairwise meeting counts and the fairness report are identical (Decision 4).**

## Decisions Needed

- (All resolved — see Decisions.)

## Acceptance criteria

- Seeded group assignment places the lowest-ranked tier in Group 1 and the highest-ranked tier (leaders) in Group G, for every seeded round.
- Tier boundaries and group sizes are unchanged from `matrix-draw.md` §6.3: `r` groups of size `b + 1`, the rest size `b`, with Groups 1..r holding the extra pilot.
- The team-protection minimal rank-displacement swap (§6.3 step 4) operates exactly as written; no adjacency or search change is introduced by the reversed order.
- For identical standings input, group count, and seed, the per-round group compositions are identical to those produced by the pre-decision spec up to the relabeling `k ↔ G - k + 1`; all fairness-report values (matchup histogram, max duplicates, MAD, never-met pairs, lane uniformity) are unchanged by the order choice.

## Sources

- `plan/architecture-requirements/matrix-draw.md` (§6, step 3)
- `research/gliderscore-draw/README.md` (§1, §6 question 3)
