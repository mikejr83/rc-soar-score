# RC Soar Score Architecture - Contest Publishing

## Purpose and boundaries

Publishing makes a contest's results available through the public site. It is an explicit director action and is separate from synchronization:

- Synchronization stores the director's private contest data for backup and collaboration.
- Publishing creates or updates a public projection of the contest from an authorized private revision.
- A contest may remain private and unpublished indefinitely.

The private contest remains the source of truth. Public data must never be merged back into it.

## Publishing requirements

1. The application must allow only the contest director, or an authenticated session authorized for that contest, to publish it.
2. Publishing must identify the private contest revision being published. The service must reject a stale or unauthorized request without changing either the private contest or its existing public projection.
3. The service must validate the contest data, calculation version, contest state, and privacy rules before creating or updating the public projection.
4. The first successful publish must create a distinct published-contest record with its own identifier and revision history. It must record the source contest, source revision, publishing actor, and publication time. The record outlives the private contest: deleting the contest does not delete the record.
5. A later publish must replace the public projection with a new version derived from the selected private revision. It must be atomic: readers see either the previous complete projection or the new complete projection, never a partial update.
6. Publishing may occur while a contest is running or after it is completed. The director must be able to publish a final update after offline administration.
7. A failed publish must leave the private contest and the last successful public projection unchanged. The application must show the failure and allow a retry.
8. Publish requests must be safe to retry. The service must not create duplicate published contests or duplicate publication effects for the same request.
9. The service must retain an audit record of each successful and rejected publication attempt, including the source revision and actor.

## Public projection and privacy

The public projection must contain only data needed for public contest viewing. At minimum this includes contest identity and dates, host and location, discipline, participant display data, teams when applicable, matrix information, scores, rankings, and the publication status. Participant email addresses and other private director data must never be published.

The projection must retain the calculation metadata needed to explain or reproduce displayed results, including the matrix revision, contest configuration revision, discipline rules version, and calculation version. The raw score values the director shows on printed score sheets (flight time, launch height, and other entered or flagged score fields, but not landing-table ids or free text) are public, as `raw_components` on each score. Other raw private inputs, audit history, pending mutations, and review-request details are not public unless a separate requirement explicitly permits them.

## Visibility and update policy

Publishing and visibility are independent:

- **Public**: the published projection can be found and viewed by anyone without an account.
- **Unlisted**: the projection is not searchable or generally listed, but remains available through its link and to participants.

The first publish must default to **Unlisted**. The director may change visibility between **Unlisted** and **Public**. Changing visibility must not modify the private contest data.

The director must be able to choose when eligible result changes are copied to the public projection:

- **Automatic**: publish eligible changes as they are accepted.
- **Round completion**: publish when a round is complete according to the contest's completion rules.
- **Manual**: publish only after the director confirms the round or contest is ready.

This policy controls public projection updates; it does not prevent private scoring, synchronization, or recalculation.

## Hiding overall results

The director may hide overall results, as defined in [contest-state-and-transitions.md](contest-state-and-transitions.md). Publishing continues to update the projection while results are hidden. The published record carries the hiding setting (the round through which standings are shown, and when hiding began) so the public site applies it without reading the private contest. While results are hidden the site shows overall scores and placing only through that round, and still shows round scores and flight-group positions. Hiding ends by the same rules even if the private contest has been deleted.

## Anonymous publishing

A director may publish an offline contest without creating an account. Anonymous publishing does not create ordinary remote backup data and does not make the director's private contest data available for synchronization.

The service must verify control of a private email address before accepting the first anonymous publish:

1. The offline application prepares a publish request and connects to the service.
2. The director supplies an email address.
3. The service sends a single-use verification code.
4. The code expires after 10 minutes; another code cannot be sent to the same address until 2 minutes after the previous request.
5. The director enters the code, and the service validates it.
6. After successful validation, the service creates the published projection and associates it with a non-public anonymous publisher record.

The email address must remain private and must be used only for verification, publication management, and future claiming. The service must apply rate limits and must not disclose whether an email address has previously published a contest.

An anonymously published contest may be claimed by an account created with the verified email address. Claiming must transfer publication management without changing the public projection or its history.

## Deletion and delisting

Deleting a contest does not remove its published record. See [contest-state-and-transitions.md](contest-state-and-transitions.md).

A published record is public record and cannot be removed by its owner directly. The owner, or the account closure flow acting for the owner, raises a delist request, and a system administrator approves or denies it. Approval makes the record `Delisted` and removes it from public access. Denial leaves it unchanged. Permanently purging the content of a delisted record is a separate administrator action. Requests are retained as the record of the decision.

Participants do not delist publications. A participant removes their own identifying details from published results through redaction, which is automatic and needs no approval.
