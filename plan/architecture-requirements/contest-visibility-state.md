# RC Soar Score Architecture - Public-Site Visibility

Publication and visibility are separate controls. A contest must be published by a contest director before its public projection can be viewed. The first publication defaults to `Private`; the director can then change the visibility of the published projection.

| State     | Meaning                                                                                                   | Entry condition                                                                                               | Exit / next transition                     |
| --------- | --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| `Public`  | The published contest and its progress are searchable and viewable without an account.                    | The contest director marks the published projection as public.                                                | `Public -> Hidden` or `Public -> Private`  |
| `Hidden`  | The published contest is not searchable or generally listed, but is available to authorized participants. | The contest director marks the published projection as hidden.                                                | `Hidden -> Public` or `Hidden -> Private`  |
| `Private` | The published contest is not searchable or publicly viewable.                                             | The first publication defaults to private, or the contest director marks the published projection as private. | `Private -> Hidden` or `Private -> Public` |

## Public

A published contest can be marked as public by the contest director. It then becomes available through public-site searching and can be viewed without an account.

## Hidden

A published contest can be marked as hidden by the contest director. It is excluded from public searching and general listings but remains available to authorized participants.

## Private

A published contest can be marked as private by the contest director. Its public projection remains unavailable to general viewers, while the private contest remains available to authorized users as permitted by the access rules.
