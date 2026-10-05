# RC Soar Score User Interface - Participant Scoring

Participant scoring is mobile-first and is opened through the most recently issued invitation link. The invitation identifies the participant and permitted team scope without requiring account creation. An expired or superseded link shows how to obtain a new link and does not reveal contest data.

## Overview

The overview shows contest name, participant name, participant number when enabled, scoring-access state, and one row per round. Each row shows round, group, lane when assigned, and task type when applicable.

Only the first round without a submitted score shows `Enter`. A round with a submission shows `View`. A participant may navigate to prior completed views but cannot skip ahead to later entry. Retired participants retain read-only access and see that rounds from their retirement round onward are locked and scored as zero.

A score the director resets (for example after moving the pilot to the group they actually flew in) returns its round to `Enter`, and the overview explains that the score must be entered again. A pilot added late may have rows credited to earlier rounds; such a row shows both the round it is credited to and the round in which it is flown.

## Entry and review

The entry form renders the discipline-specific fields plus a generic **Flight Penalty** input. Once the director applies a cumulative penalty to the flight, it is shown read-only on the score; the participant cannot enter or change it. The form has `Submit`, `Back`, and available previous/next navigation. Before submission, a result that would produce zero shows a confirmation explaining the consequence. After accepted submission, the form becomes read-only and displays submission time and status.

When review requests are enabled and no review is open for the flight assignment, `Request review` is available only for a preliminary (`Submitted`) score that is not locked. It opens an editable form prepopulated with the participant's submitted values and an optional explanation field. The proposal may change the flight penalty but not the cumulative penalty. Submit is disabled until at least one value changes. After submission, the form displays the pending review state and highlights the modified fields. If the score has been marked `Official` by the contest director or is locked at the score, group, round, or contest level, review request actions are hidden.

## Re-flights

When the participant has a re-flight for a round, the round row shows it. The view identifies which flight supplied the official result, and shows any re-flight that is pending or cancelled.

## Results

After a score is submitted, show preliminary group results with pilot name, discipline values, raw score, and round score. Participant submissions update this view as received, independent of the public update policy. Pending reviews are indicated, and the displayed official values remain unchanged until the director resolves the review.

Show the participant's current placement with up to three pilots above and below. While the director is hiding overall results, placement is shown as of the hidden-through round with a note naming that round; group results and round scores stay current. Estimated placements for missing scores are labeled as estimates. Pending reviews affecting the placement are indicated.

All participant views support loading, unavailable-network, invalid-invitation, closed-scoring, rejected-submission, and retry states. A submission must remain visible locally until its server acknowledgement or a clear rejection reason is received.
