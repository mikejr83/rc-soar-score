# Publication

## Published contest identity

A published-contest record has its own stable identifier, source contest identifier, ownership/claim metadata, current visibility, and publication history. It is a public projection, never a source of private contest data.

## Publication revision

Each successful publish creates an atomic immutable projection revision containing only public data: contest identity and dates, host/location, permitted participant display data, teams when applicable, matrix information, scores, rankings, and calculation metadata. It records source contest revision, configuration revision, matrix revision, discipline rules version, calculation version, actor, and publication time.

Readers see either the previous complete revision or the new complete revision. A failed or stale publish changes neither private data nor the previous projection. Rejected and successful publish attempts are retained in audit history.

The first publish defaults to `Private`. Visibility (`Private`, `Hidden`, `Public`) is independent of publication status and does not change the private contest. Anonymous publishing uses a verified private email and a non-public anonymous publisher record; claiming transfers management without changing public history.

Participant email, invitation credentials, pending mutations, review details, raw private inputs, and director-only audit data are excluded unless a separate requirement explicitly permits them.
