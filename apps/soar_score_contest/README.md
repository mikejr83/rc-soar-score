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

### Demo data

A fresh install lists no contests. For development, run in demo mode:

```bash
flutter run -d windows --dart-define=SOAR_SCORE_DEMO=true
```

Demo mode opens `soar_score_demo.db` instead of `soar_score.db`, so your real data is never touched. On the first start with an empty demo database it loads five example contests, one in each lifecycle state, with participants, teams, drawn matrices, entered F5J scores and calculated results. The demo data is kept current with the models; see the Demo Data section of the root `AGENTS.md`. Add `--dart-define=SOAR_SCORE_DEMO_RESET=true` to start over from a new demo database. Both defines are ignored in release builds. See the root [README](../../README.md#demo-data-development-only) for details, including the VS Code launch configurations and tasks.

### Where the data lives

The database is `soar_score.db` (`soar_score_demo.db` in demo mode) in the per-user application support folder, which on Windows is `%APPDATA%\Laminar Stack\RC Soar Score\` (the company and product names come from `windows/runner/Runner.rc`). Closing the app closes the server and the database.

For development, `--dart-define=SOAR_SCORE_LOCAL_DATA_DIRECTORY=<path>` uses that folder instead (created if missing, ignored in release builds). The VS Code Windows launch configurations and tasks use `.local-data` in the workspace (git-ignored), so they start with an empty database rather than the one in `%APPDATA%`; remove the define to use that one. The sign-in is shared either way, because the Auth0 session is stored per Windows user, not beside the database.

Nothing is released yet, so the database schema changes in place. If the app fails at startup with an error about a missing table, the file was made by an older build: delete `soar_score.db` and start again. In demo mode, use `SOAR_SCORE_DEMO_RESET=true` instead, which also loads the demo data again.

### Manual checklist: offline proof of concept

1. Build the app with `--dart-define=SOAR_SCORE_DEMO=true` and delete any existing `soar_score_demo.db`.
2. Disconnect the network (turn off Wi-Fi or unplug Ethernet).
3. Start the app, choose **Continue offline**, and confirm the contest list shows the five demo contests, from "Autumn F5J Classic" to "Spring F3J Challenge".
4. Close the app and start it again with the network still disconnected. Confirm the same five contests appear, not ten.
5. Confirm `soar_score_demo.db` exists in the folder above.
6. Reconnect the network and note anything that behaves differently. Sign-in and synchronization are not part of this proof of concept.

File anything unexpected as a GitHub issue under the native offline proof-of-concept epic (#190).

## Web

```bash
flutter run -d chrome
```

The web build talks to the API server at `SOAR_SCORE_API_BASE_URL` (default `http://localhost:8080`, set with `--dart-define`) instead of an embedded one.
