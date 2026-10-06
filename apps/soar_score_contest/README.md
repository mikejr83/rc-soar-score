# soar_score_contest

The contest administration app. It is one Flutter code base: the web build is the online app and the Windows build is the offline app.

## Native offline app (Windows)

The Windows build starts an embedded API server inside the app, bound to `localhost` on a free port and backed by a local SQLite database. The app's own `ApiClient` talks to it, so it works with no network at all.

### Prerequisites

- Flutter 3.47.x with Windows desktop support (see the root [README](../../README.md#prerequisites--toolchain) for the toolchain pins)
- Visual Studio with the "Desktop development with C++" workload
- `melos bootstrap` run once from the repository root

### Build and run

From this folder:

```bash
flutter run -d windows
```

A release executable comes from `flutter build windows`.

### Demo contests

Nothing can create contests in the app yet, so a fresh install lists none. For development, build or run with the demo seed:

```bash
flutter run -d windows --dart-define=SOAR_SCORE_SEED_DEMO=true
```

On the first start with an empty database this inserts three sample contests. It does nothing on a database that already holds contests. It is off by default and ignored in release builds. See the root [README](../../README.md#demo-contests-development-only) for details.

### Where the data lives

The database is `soar_score.db` in the per-user application support folder, which on Windows is `%APPDATA%\Laminar Stack\RC Soar Score\` (the company and product names come from `windows/runner/Runner.rc`). Closing the app closes the server and the database.

Nothing is released yet, so the database schema changes in place. If the app fails at startup with an error about a missing table, the file was made by an older build: delete `soar_score.db` and start again. This also reseeds the demo contests.

### Manual checklist: offline proof of concept

1. Build the app with `--dart-define=SOAR_SCORE_SEED_DEMO=true` and delete any existing `soar_score.db`.
2. Disconnect the network (turn off Wi-Fi or unplug Ethernet).
3. Start the app, choose **Continue offline**, and confirm the contest selection page lists the three sample contests: "Front Range F5J Open", "Club Thermal Fun Fly" and "Autumn ALES Classic".
4. Close the app and start it again with the network still disconnected. Confirm the same three contests appear, not six.
5. Confirm `soar_score.db` exists in the folder above.
6. Reconnect the network and note anything that behaves differently. Sign-in and synchronization are not part of this proof of concept.

File anything unexpected as a GitHub issue under the native offline proof-of-concept epic (#190).

## Web

```bash
flutter run -d chrome
```

The web build talks to the API server at `SOAR_SCORE_API_BASE_URL` (default `http://localhost:8080`, set with `--dart-define`) instead of an embedded one.
