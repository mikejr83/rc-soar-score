# RC Soar Score Architecture - Public-Site Visibility

Publication, visibility, and hiding of results are separate controls. A contest must be published by a contest director before its public projection can be viewed. A contest that has not been published is private to its director. The first publication defaults to `Unlisted`; the director can then change the visibility of the published record.

| State      | Meaning                                                                                | Entry condition                                                                        | Exit / next transition |
| ---------- | -------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- | ---------------------- |
| `Public`   | The published contest and its progress are searchable and viewable without an account. | The contest director marks the published record as public.                             | `Public -> Unlisted`   |
| `Unlisted` | The published contest is not searchable or listed, but is available through its link.  | The first publication defaults to unlisted, or the director marks the record unlisted. | `Unlisted -> Public`   |
| `Delisted` | The published contest has been removed from public access by an administrator.         | A system administrator approves a delist request.                                      | None for the director  |

## Public

A published contest can be marked as public by the contest director. It then becomes available through public-site searching and can be viewed without an account.

## Unlisted

A published contest can be marked as unlisted by the contest director. It is excluded from public searching and general listings but remains available to anyone with its link and to its participants.

## Delisted

A delisted record is not viewable by the public. The director cannot set or clear this state. It results only from an approved delist request, and permanently purging the record's content is a separate administrator action.

## Hiding overall results

Hiding is not a visibility. It withholds the overall scores and placing of a published contest, and of participant result views, as of a recorded round while the contest continues. It applies to a `Public` or `Unlisted` record alike, and ends as defined in [contest-state-and-transitions.md](contest-state-and-transitions.md).
