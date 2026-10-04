# Publication

## Published contest identity

A published-contest record has its own stable identifier, an optional source contest identifier, ownership/claim metadata, current visibility, and publication history. The source contest identifier is cleared when the contest is deleted, because the record outlives the contest. The owner is a public profile, never the account itself. It is a public projection, never a source of private contest data.

## Publication revision

Each successful publish creates an atomic immutable projection revision containing only public data: contest identity and dates, host/location, permitted participant display data, teams when applicable, matrix information, scores, rankings, and calculation metadata. It records source contest revision, configuration revision, matrix revision, discipline rules version, calculation version, actor, and publication time.

Readers see either the previous complete revision or the new complete revision. A failed or stale publish changes neither private data nor the previous projection. Rejected and successful publish attempts are retained in audit history.

The first publish defaults to `Unlisted`. Visibility (`Unlisted` or `Public`) is independent of publication status and does not change the private contest. A record can also be `Delisted` by a system administrator. Anonymous publishing uses a verified private email and a non-public anonymous publisher record; claiming transfers management without changing public history.

Participant email, invitation credentials, pending mutations, review details, raw private inputs, and director-only audit data are excluded unless a separate requirement explicitly permits them.

## Results hiding

The record carries the contest's results-hiding setting: the round through which overall scores and placing are shown, and when hiding began. The public projection withholds overall scores and placing beyond that round while hiding is in effect, and always shows round scores and flight-group positions. Hiding ends when the contest director turns it off, when the contest is completed, or 24 hours after it began, even if the private contest has since been deleted. Publishing keeps updating the projection throughout.

## Participants and redaction

Published results refer to pilots by an opaque key. Each pilot's identifying details are stored separately so they can be removed without changing scores, ranks, or any earlier revision. A pilot linked to an account can be tied through the account's public profile to their results across contests. Redaction clears the details, is irreversible, needs no approval, and applies to every revision. A participant with no account can only be redacted by a system administrator.

## Delisting

A delist request belongs to a published record, not to its contest. It states who asked, why, and the administrator's decision. Only the owner or the account closure flow may raise one, and only for a record that is currently public. At most one request is pending per record. Approval makes the record `Delisted`; denial leaves it unchanged. Requests are never deleted.
