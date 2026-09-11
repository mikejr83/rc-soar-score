# Reviews and Invitations

## Review request

A review request belongs to one score placeholder and preserves the current preliminary score (`Submitted`), proposed raw components, cumulative penalty, optional participant message, requester, base score revision, and request time. It has an explicit state such as `Submitted`, `UnderReview`, `Approved`, `Rejected`, or `Superseded`, plus decision actor, time, and message.

A participant may submit a review request only against a preliminary (`Submitted`) score if review requests are enabled in the contest and the score is not locked. A review request cannot be submitted on scores that are marked `Official` or `Locked`. A request never mutates the original submission in place. If an official edits or marks the score official while a review is pending, the review request is superseded.

## Invitation

An invitation targets one contest participation link and stores a protected credential representation, monotonically increasing invitation revision, issue/replacement/revocation/expiry state, delivery outcomes, and audit references. The raw credential is never stored in logs or audit records.

Only the latest non-revoked invitation revision authorizes access. A pilot invitation authorizes only that pilot; a non-flier invitation may select only pilots on the same contest team. Every read and mutation still checks lifecycle, scoring access, locks, retirement, assignment, and score state.

Invitation access, failed attempts subject to rate limits, issuance, replacement, revocation, and delivery requests are auditable without storing credentials or message contents.
