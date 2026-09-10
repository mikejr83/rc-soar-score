# Scores and Results

## Score placeholder and attempt

A score placeholder belongs to one participant assignment and identifies the scheduled and credited round, group, and flight attempt. It exists before entry and distinguishes `NotEntered`, draft, submitted, zero, retired, review, official, and locked presentation outcomes.

Each accepted submission is an immutable score attempt containing:

- canonical raw components, including integer `Cumulative Penalty`;
- zero/status reasons and discipline-specific deductions;
- actor, authority, invitation/access reference, source device, client mutation ID, and acceptance time;
- base score revision, contest configuration revision, matrix revision, discipline rules version, and calculation version.

Keep the original participant/official submission, every review proposal, superseded attempts, and the current official component set distinct. A director correction creates a new authorized official revision and never overwrites source history.

## Calculation results

Derived records or revisions store discipline raw score, group score, contest total, dropped-round decision, ranking, and team total with the exact input revisions and calculation metadata. Recalculation preserves all raw inputs, score state, review history, and audit records.

Canonical pipeline: raw components -> discipline raw score -> group score -> contest total -> dropped-round selection -> ranking/team totals. Cumulative penalties, discipline deductions, and director penalties are distinct components and stages.

All-zero groups produce zero without division by zero. Missing, explicit zero, and retired outcomes remain distinguishable. Drafts and queued submissions never produce official derived results.

## Locks and review interaction

Contest, round, group, assignment, and score lock scope must be represented independently or with an explicit precedence rule. A locked score cannot be modified by participant review. The final review eligibility policy remains an open decision and must be resolved before implementation.
