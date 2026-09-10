# Reviews and Invitations

## Review request

A review request belongs to one score placeholder and preserves the current official score, proposed raw components, cumulative penalty, optional participant message, requester, base score revision, and request time. It has an explicit state such as `Submitted`, `UnderReview`, `Approved`, `Rejected`, or `Superseded`, plus decision actor, time, and message.

A request never mutates the original submission. If the official score changes after the request's base revision, the director must explicitly approve, reject, or supersede it.

## Invitation

An invitation targets one contest participation link and stores a protected credential representation, monotonically increasing invitation revision, issue/replacement/revocation/expiry state, delivery outcomes, and audit references. The raw credential is never stored in logs or audit records.

Only the latest non-revoked invitation revision authorizes access. A pilot invitation authorizes only that pilot; a non-flier invitation may select only pilots on the same contest team. Every read and mutation still checks lifecycle, scoring access, locks, retirement, assignment, and score state.

Invitation access, failed attempts subject to rate limits, issuance, replacement, revocation, and delivery requests are auditable without storing credentials or message contents.
