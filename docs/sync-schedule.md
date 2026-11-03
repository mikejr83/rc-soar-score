# When the apps talk to the service

The Windows contest app keeps contests on the device and syncs with the
service at `api.rcsoarscore.com`. To keep many directors' apps from loading
the API, it asks as rarely as it can. The web app does not poll at all.

## Health checks (`GET /health`)

Only while the service is not known to be reachable.

- At start-up, then after each failure at 15 s, 30 s, and then every 60 s.
- They stop at the first success. After that, a successful sync is the proof
  that the service is reachable, and a sync that finds no connection restarts
  the health checks.
- An operating system network change, and the "Retry now" button of the cloud
  indicator, check once.
- Nothing runs while the app is minimised; coming back checks at once if the
  service is not known to be reachable.
- The web app starts as reachable and never polls. A failed request or "Retry
  now" tells it otherwise.

## Sync checks

Only while signed in and the service is reachable.

| Where the director is | Check | Every |
| --- | --- | --- |
| Landing page and Contests pages (no contest selected) | the director's own data, plus a look for contests made on another installation | 10 min |
| Inside a contest | that contest, and the director's own data | 5 min |

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
