# When the apps talk to the service

The Windows contest app keeps contests on the device and syncs with the
service at `api.rcsoarscore.com`. To keep many directors' apps from loading
the API, it asks as rarely as it can. The web app has no local copy to sync;
it checks whether the data on screen changed (see "Web refresh" below).

## Health checks (`GET /health`)

Only while the service is not known to be reachable.

- At start-up, then after each failure at 15 s, 30 s, and then every 60 s.
- They stop at the first success. After that, a sync that gets an answer from
  the service (including a refusal such as an expired sign-in) is the proof
  that it is reachable, and a sync that finds no connection restarts the
  health checks. A server error (5xx) says nothing either way and changes
  nothing.
- An operating system network change, and the "Retry now" button of the cloud
  indicator, check once.
- Nothing runs while the app is minimised; coming back checks at once if the
  service is not known to be reachable.
- The web app starts as reachable and never health-checks. A failed request or
  "Retry now" tells it otherwise.

## Sync checks

Only while signed in and the service is reachable.

| Where the director is                                 | Check                                                                          | Every  |
| ----------------------------------------------------- | ------------------------------------------------------------------------------ | ------ |
| Landing page and Contests pages (no contest selected) | the director's own data, plus a look for contests made on another installation | 10 min |
| Inside a contest                                      | that contest, and the director's own data                                      | 5 min  |

- Each wait varies by up to 10 percent, so installations that started together
  do not ask together. Checks never overlap, and the engine runs syncs one after
  another.
- Any sync resets the timer: a manual one, one after a local change, or a
  scheduled one. The next check comes one interval after it.
- Opening a contest that has not synced for 5 min syncs it at once.
- Nothing runs while the app is minimised; coming back runs an overdue check
  at once.
- Server errors keep their own retry backoff (`SyncScheduler`); a sync that
  finds no connection waits for the health checks to see the service again.

## Status bar

The sync entry in the status bar shows the status and when the sync last ran.
Inside a contest a click opens the Sync page. Outside a contest it shows the
signed-in account's data, and a click syncs now.

The intervals are constants: `AppConnectivity` (health) and `SyncPoller`
(sync checks).

## Web refresh

The web app reads and writes the hosted service directly, so there is nothing
to push or pull, but a page that is already open goes stale when someone else
writes: pilots scoring from their phones while the director watches the Scoring
page, or a second director. Without a way to be told, people reload the page
again and again, which loads the service.

- A check is one small request, `GET /api/v1/sync/revision`, that returns the
  highest sequence of the contest's log (or of the director's own data). Every
  accepted write moves it, pilots' self-scored attempts included. The data
  itself is read only when the number moved.
- The schedule is the sync check schedule above: 5 min in a contest, 10 min
  outside one, 10 percent jitter, nothing while signed out or while the tab is
  hidden (a hidden tab that comes back runs an overdue check at once), checks
  never overlap, and any check or click pushes the next one back. Opening a
  contest not checked for 5 min checks it at once.
- When the number moved, the pages wrapped in `ReloadOnSync` reload quietly,
  with the protections they already have for rows being typed.
- The status bar entry reads "Refresh". A click reloads the pages whether or
  not the number moved. A failed check shows "Refresh failed" and why in its
  tooltip.
- Contests created or renamed on another device show up on the Contests page
  after a Refresh; the 10 min check does not look at the list.

The code is `RevisionAppSync`; the intervals are the same `SyncPoller`
constants.
