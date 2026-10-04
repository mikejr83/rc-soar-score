# Open Pre-Implementation Tickets — Triage Against the Data Model

This triage covers the 13 pre-implementation tickets still marked `Open`. It asks one question of each: does it block the domain models (mvp 035) or the Drift schema (mvp 036), or can it be settled later? It also records where the data model and architecture documents already answer the ticket.

These are recommendations. No ticket status has been changed. Moving a ticket to `Decided` needs the owner's call.

## Summary

| Ticket                                            | Blocks 035/036? | Recommendation                                                                                  |
| ------------------------------------------------- | --------------- | ----------------------------------------------------------------------------------------------- |
| [019](019-access-public-site-draft-visibility.md) | No              | Close Q1 to Q3 from the model; keep Q4 (in-progress group display) as a UI decision             |
| [020](020-access-director-penalty-authority.md)   | **Possibly**    | Needs one decision: is disqualification a feature? It would add an outcome value                |
| [022](022-state-publish-unpublish-rules.md)       | No              | Close as answered: there is no unpublish                                                        |
| [023](023-state-contest-ended-reversible.md)      | No              | Close as answered: not reversible in the first release                                          |
| [024](024-state-round-completion-gate.md)         | No              | Close as answered: completeness is derived, the director locks rounds                           |
| [027](027-matrix-seeded-team-protection.md)       | No              | Draw-engine decision; defer to the draw work                                                    |
| [028](028-matrix-back-to-back-constraint.md)      | No              | Draw-engine decision; defer. Would add a contest option only if adopted                         |
| [029](029-matrix-lane-count-source.md)            | No              | Close as answered: lane count is derived from group size                                        |
| [030](030-matrix-fairness-score-scale.md)         | No              | Draw-engine decision; defer                                                                     |
| [032](032-ui-offline-capable-pages.md)            | No              | UI decision; ticket 037 and the status area (023) need it later                                 |
| [033](033-ui-score-entry-responsive.md)           | No              | UI decision; defer                                                                              |
| [034](034-business-reflight-decline-limits.md)    | No              | Answered by the re-flight model: the draw repeats until filled, then the re-flight is cancelled |
| [035](035-business-reflight-better-of-scoring.md) | No              | Business-rule question; the model was left alone by choice                                      |

Only 020 can affect a stored field, and only if disqualification is added. Everything else can proceed in parallel with 035 and 036.

## Detail

### 019 — Public site visibility of in-progress scores

- **Q1 and Q3 (drafts, pending review).** The data model's global invariants say drafts and queued local submissions are not accepted data and do not affect lifecycle, completion, rankings or publication ([data/README.md](../../architecture-requirements/data/README.md)). So drafts are never public.
- **Q2 (round completion mode).** [round.md](../../data-model/entities/round.md) defines completeness as derived: every current assignment credited to the round has an official score (including official zero and retired outcomes) and no review request is open. A round with an open review request is therefore not complete, and `RoundCompletion` mode does not publish it.
- **Q4 (groups part-way through).** Not a data question. It is a presentation rule for the public site and for the publication projection. Keep it open for the publishing and public-site tickets.
- **Schema impact.** None. `public_update_mode` (`Automatic`, `RoundCompletion`, `Manual`) already exists in [contest-options.md](../../data-model/contest-options.md).

### 020 — Director penalty and disqualification authority

- **Answered.** [scores-and-results.md](../../architecture-requirements/data/scores-and-results.md): the cumulative penalty is set only by the contest director or a local operator acting under the director's authority. Participants and helpers see it read-only, and the service rejects a participant submission or review proposal that sets it. It is unilateral, with no approval workflow. It can be applied through an official revision, so it can follow a pilot's confirmation. The audit trail records it. The flight penalty is a separate score component entered with the score.
- **Not answered.** No requirement or entity mentions disqualification. Ticket 012 decided the outcome values (`NOT_ENTERED`, `ZERO`, `RETIRED`) with no disqualified value.
- **Decision needed before 035 reaches the scores family.** Either disqualification is represented as an official zero with an audited reason, which needs no schema change, or it is a distinct outcome, which does.
- **Also open.** Whether the pilot is notified of a penalty. The model records it in the score breakdown and audit events and says nothing about notification. This is a UI and notification question.

### 022 — Publish and unpublish rules

- **Answered by the model.** A published record is permanent public record. A director cannot remove it, and removal goes through a delist request decided by a system administrator ([contest-publishing.md](../../architecture-requirements/contest-publishing.md), [publication.md](../../architecture-requirements/data/publication.md)). Each publish creates a new versioned projection. There is no round-level unpublish.
- **Concealing results** is covered by results hiding: standings are withheld as of a round while round scores stay visible ([contest-state-and-transitions.md](../../architecture-requirements/contest-state-and-transitions.md)).
- **Recommendation.** Mark as decided with that summary. If a round-level unpublish is wanted, it is a new requirement, not an open question.

### 023 — Is "contest ended" reversible?

- **Answered.** There is no ordinary transition back from `Completed`. Corrections to a completed contest use the score correction and audit workflow and preserve the completed lifecycle. If reopening is ever required, it must be added as an explicit, authorized transition ([contest-state-and-transitions.md](../../architecture-requirements/contest-state-and-transitions.md)).
- **Recommendation.** Decide "not reversible in the first release". Calculation revisions on correction follow ticket 010.

### 024 — Round completion gate

- **Answered.** Completeness is derived, never stored (see 019). Rounds have a stored status of `Open`, `Locked` or `Cancelled`; the director toggles `Open` and `Locked`, and each change is audited ([round.md](../../data-model/entities/round.md)). While `Locked`, score entry and assignment moves are rejected unless the director overrides with a recorded reason. Recalculation on a late edit follows ticket 010.
- **Residual.** Whether the UI asks the director to confirm a lock. That is a UI decision.

### 027, 028, 030 — Draw engine

- Pure algorithm and rules questions about the matrix draw. They do not change an entity. A back-to-back constraint (028) would add a structural contest option if adopted, and seeded team protection (027) would add behaviour to the existing `SeededManOnMan` mode. Decide them with the draw engine, not the schema.

### 029 — Lane count source

- **Answered.** When the lane mode is `Random`, the lane is between 1 and the largest group size of that round; with `None` the lane is null ([matrix_assignment.md](../../data-model/entities/matrix_assignment.md)). Lane count is derived from group size, not configured, and `lane_mode` is the only contest option. A pilot dropping out does not change the stored data.

### 032, 033 — UI

- Neither changes an entity. 032 (offline-capable pages) will be needed by the status area and sync UI (tickets 023 and 037). The native application runs the whole application against its local database, so the baseline answer is that every page works offline except those that need the service: sign-in, publishing, delist requests, and installation activation.

### 034, 035 — Re-flights

- The re-flight entities were redesigned on the data-model branch, and the earlier decision was to leave these two tickets alone. [re_flight.md](../../data-model/entities/re_flight.md) already says a drawn pilot may decline, the draw repeats until the group is filled, and if it cannot be filled the re-flight is cancelled. That answers 034 without a numeric limit. 035 is a business-rule question about the better-of scoring and does not affect field definitions.

## Suggested next steps

1. Owner decides ticket 020's disqualification question.
2. Mark 022, 023, 024 and 029 as decided, using the summaries above. Mark 034 as decided too if the cancel-when-exhausted rule is acceptable.
3. Leave 027, 028, 030, 032, 033 and 035 open for the draw, UI and business-rule work.
4. Resolve 019 Q4 when the publishing work starts.
