# Scores and Results

## Score placeholder and attempt

A score placeholder belongs to one participant assignment and identifies the scheduled and credited round, group, and flight attempt. It exists before entry and distinguishes `NotEntered`, draft, submitted, zero, retired, review, official, and locked presentation outcomes.

Each accepted submission is an immutable score attempt containing:

- canonical raw components, including an optional integer `Flight Penalty`. A director-applied `Cumulative Penalty` is added only on a director-authority submission or an official revision;
- zero/status reasons and discipline-specific deductions;
- actor, authority, invitation/access reference, source device, client mutation ID, and acceptance time;
- base score revision, contest configuration revision, matrix revision, discipline rules version, and calculation version.

Keep the original participant/official submission, every review proposal, superseded attempts, and the current official component set distinct. A director correction creates a new authorized official revision and never overwrites source history.

## Flight penalty

A flight penalty is a deduction for an infraction on one flight, for example flying out of the assigned group. It is a generic score component in every discipline, entered with the score by whoever enters it: the pilot, a helper, or the director. It is a nullable non-negative integer in the flight's component set, and absent or zero means no deduction. A review request may propose changing it.

It is part of the round score. The calculation deducts it from the discipline raw score, which never goes below zero, before the group score is computed, so a dropped round drops its flight penalty. It is distinct from the penalties a discipline profile computes itself, such as the F3J late-landing penalty and the F5J launch-height penalty, and from the director-only cumulative penalty below.

## Cumulative penalty

A cumulative penalty is a deduction the contest director applies to a flight. It is a judgement call that the official discipline information may guide. It is a nullable non-negative integer in the flight's official component set: absent means no penalty was ever applied, a positive value is the points deducted, and zero means a penalty was applied and later removed.

Only the contest director, or a local operator under the director's authority, may set it. Participants and helpers see it read-only, and the service rejects a participant submission or review proposal that carries it. It is deducted from the pilot's contest total after dropped rounds. It is never dropped with its round, and it still counts if the flight is later re-flown. To remove it, the director zeros it through an official correction, which keeps the earlier value in the history. Results show the flight in which the penalty was given, and the penalties are summed in the total.

## Calculation results

Derived values are always computable from the immutable raw components (the current official component set for each score), the contest configuration, the matrix, and the discipline profile. Because recomputing them in every client in real time is costly, the discipline raw score, group score, contest total, dropped-round decision, ranking, and team total are stored as derived results: per flight, per pilot as of each completed round, and per team as of each completed round. Stored results are never an input to anything and are never merged. Each carries the configuration revision, matrix revision, and calculation version it was computed under, so a stale one is detected and recomputed. Only the calculator writes them: the service, or the active administration installation while offline. Other clients receive them read-only, and the service recomputes after it receives changed raw scores. A published projection freezes the values shown at publish time with their calculation metadata. Recalculation never changes raw inputs, score state, review history, or audit records.

Canonical pipeline: raw components -> discipline raw score -> group score -> contest total -> dropped-round selection -> ranking/team totals. A cumulative penalty (applied by the contest director to a flight), a flight penalty (entered with the score), and a discipline deduction (computed by the discipline profile) are distinct components. The flight penalty and the discipline deduction are part of the discipline raw score; the cumulative penalty is applied at the contest total.

All-zero groups produce zero without division by zero. Missing, explicit zero, and retired outcomes remain distinguishable. Drafts and queued submissions never produce official derived results.

## Locks and review interaction

Contest, round, group, assignment, and score lock scopes are evaluated hierarchically (an assignment has exactly one score, so its lock and the score lock are the same lock) (`Contest.Locked > Round.Locked > Group.Locked > Score.Locked`). A locked score cannot be modified by participant review. A participant may submit a score review request against any `Submitted` score as long as review requests are enabled for the contest, the score is not locked, and no other review for that assignment is pending.
