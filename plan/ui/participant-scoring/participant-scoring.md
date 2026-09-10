# RC Soar Score User Interface - Participant Scoring

Participant scoring is mobile-first and is opened through the most recently issued invitation link. The invitation identifies the participant and permitted team scope without requiring account creation. An expired or superseded link shows how to obtain a new link and does not reveal contest data.

## Overview

The overview shows contest name, participant name, pilot number when enabled, scoring-access state, and one row per round. Each row shows round, group, lane when assigned, and task type when applicable.

Only the first round without a submitted score shows `Enter`. A round with a submission shows `View`. A participant may navigate to prior completed views but cannot skip ahead to later entry. Retired participants retain read-only access and see that future rounds are locked and counted according to the retirement policy.

## Entry and review

The entry form renders the discipline-specific fields plus cumulative penalty. It has `Submit`, `Back`, and available previous/next navigation. Before submission, a result that would produce zero shows a confirmation explaining the consequence. After accepted submission, the form becomes read-only and displays submission time and status.

When review requests are enabled and no request is open for the score, `Request review` opens an editable copy of the submitted values and a short reason field. Submit is disabled until a value changes. After submission the form becomes read-only and marks changed fields and the pending review state. A locked or completed score hides review actions.

## Results

After a score is submitted, show preliminary group results with pilot name, discipline values, raw score, and round score. Participant submissions update this view as received, independent of the public update policy. Pending reviews are indicated, and the displayed official values remain unchanged until the director resolves the review.

Show the participant's current placement with up to three pilots above and below. Estimated placements for missing scores are labeled as estimates. Pending reviews affecting the placement are indicated.

All participant views support loading, unavailable-network, invalid-invitation, closed-scoring, rejected-submission, and retry states. A submission must remain visible locally until its server acknowledgement or a clear rejection reason is received.
