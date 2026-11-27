# Repository scripts

Run these commands from the repository root. **PowerShell + Bash** marks scripts with both a `.ps1` and a `.sh` wrapper. The command examples in each paired entry use the same options where the wrappers support them.

## Verification and testing

### [verify.ps1](./verify.ps1) — PowerShell

Runs Melos bootstrap, a format check, static analysis, unit and widget tests, and the configured build tasks. Requires Melos and the repo's Flutter/Dart toolchain. Takes no options.

```powershell
./scripts/verify.ps1
```

### [draw-bench.ps1](./draw-bench.ps1) / [draw-bench.sh](./draw-bench.sh) — PowerShell + Bash

Runs the Dart matrix draw benchmark and reports mean absolute deviation, pairs that never meet, maximum repeat count, and variance.

```powershell
./scripts/draw-bench.ps1 --layout c4 --seeds 10
```

```bash
bash scripts/draw-bench.sh --check
```

- `--layout c1|c4|c10|all` selects a layout. The default is `all`.
- `--seeds N` sets the number of seeds to run.
- `--check` fails on a regression against the stored baselines.

### [test-postgres.ps1](./test-postgres.ps1) / [test-postgres.sh](./test-postgres.sh) — PowerShell + Bash

Starts a temporary PostgreSQL container and runs the data package's SQLite and PostgreSQL tests. Bash also runs the server API slice tests. Both clean up the container and require Docker and Dart.

```powershell
./scripts/test-postgres.ps1 -Port 55432 -Image postgres:18 -TestArgs @('-n', 'unit of work')
```

```bash
bash scripts/test-postgres.sh --port 55432 -- -n "unit of work"
```

- `-Port` / `-p` or `--port` selects the host port (default `54329`).
- PowerShell defaults to `postgres:18` and accepts `-Image`. Bash uses `postgres:17`.
- PowerShell's `-TestArgs` and Bash arguments after `--` are forwarded to the data package's `dart test`.

### [e2e-setup.ps1](./e2e-setup.ps1) / [e2e-setup.sh](./e2e-setup.sh) — PowerShell + Bash

Downloads Chrome for Testing and its matching ChromeDriver into `.e2e-tools/` for the browser E2E runners. Bash needs `curl` and either `unzip` or Python 3. Chrome also needs its system libraries on Linux.

```powershell
./scripts/e2e-setup.ps1 -Channel Beta -DryRun
```

```bash
bash scripts/e2e-setup.sh --version 155.0.8059.84 --dry-run
```

- `-Channel` / `--channel` selects Stable (default), Beta, Dev, or Canary.
- `-Version` / `--version` pins an exact build and takes precedence over channel selection.
- `-DryRun` / `--dry-run` prints the download plan. Omit it to install.

### [e2e-contest.ps1](./e2e-contest.ps1) / [e2e-contest.sh](./e2e-contest.sh) — PowerShell + Bash

Runs the Contest app integration tests against demo data. The default device is `windows`. Use `web` or `chrome` for headless Chrome with a fresh local E2E API server for each test file.

```powershell
./scripts/e2e-contest.ps1 -Device web -File save_failure_retry_test.dart -Name 'Retry saves'
```

```bash
bash scripts/e2e-contest.sh -d web -f save_failure_retry_test.dart -- --name 'Retry saves'
```

- `-Device` / `-d` or `--device` selects the Flutter device.
- `-File` (alias for `-TestFileName`) / `-f` or `--file` selects an integration test by filename. Omit it to run all files.
- PowerShell's `-Name` filters test names. Bash forwards arguments after `--` to Flutter.

### [e2e-score.ps1](./e2e-score.ps1) / [e2e-score.sh](./e2e-score.sh) — PowerShell + Bash

Runs the self-scoring web app integration tests in headless Chrome. Each test file gets a fresh local E2E API server and database with invitations enabled.

```powershell
./scripts/e2e-score.ps1 -File self_score_lifecycle_journey_test.dart
```

```bash
bash scripts/e2e-score.sh -f self_score_lifecycle_journey_test.dart
```

- `-File` (alias for `-TestFileName`) / `-f` or `--file` selects a test by filename. Omit it to run all files.
- Bash forwards arguments after `--` to `flutter drive`.

Both E2E runners use the tools installed by `e2e-setup`. You can also supply `CHROMEDRIVER` and `CHROME_EXECUTABLE` or put ChromeDriver on `PATH`. Set `E2E_SERVER_PORT` to change the local API port from `18080`, `E2E_STOP_AFTER` to stop the lifecycle journey after a numbered phase, or `E2E_TEST_TIMEOUT` to override the per-file browser timeout in seconds. The self-scoring default is 900 seconds. The Contest web defaults are 300 seconds for most files and 1800 seconds for the lifecycle journey.

### [hosted-smoke.ps1](./hosted-smoke.ps1) / [hosted-smoke.sh](./hosted-smoke.sh) — PowerShell + Bash

Checks that a deployed API returns HTTP 200 from `/health` and rejects an unauthenticated request to `/api/v1/contests`. The base URL defaults to `https://api.rcsoarscore.com`. Bash requires `curl`.

```powershell
./scripts/hosted-smoke.ps1 -BaseUrl https://rc-soar-score-api.fly.dev
```

```bash
bash scripts/hosted-smoke.sh https://rc-soar-score-api.fly.dev
```

## Server and database

### [build-server-image.ps1](./build-server-image.ps1) — PowerShell

Builds `local/rc-soar-score-server`, tags it with a version and `latest`, and prunes older image IDs to retain three. It prompts to start the image by default. Starting replaces any container named `rc-soar-score-api`. Requires Docker.

```powershell
./scripts/build-server-image.ps1 -Tag 2026.11.2 -NoStart
./scripts/build-server-image.ps1 -Start -Port 9090 -Network my-compose-network
```

- `-Tag` sets the version tag (default `yyyyMMdd-HHmmss`).
- `-Start` starts without prompting. `-NoStart` builds without starting or prompting.
- `-Port` sets the published host port (default `8080`).
- `-Network` joins a Docker network and defaults the PostgreSQL host to `db`. Without it, the default PostgreSQL host is `host.docker.internal`. A configured `DATABASE_URL` takes precedence over individual PostgreSQL settings.

### [reset-server-db.ps1](./reset-server-db.ps1) / [reset-server-db.sh](./reset-server-db.sh) — PowerShell + Bash

**Deletes all objects and data in the target database's `public` schema.** Stop the local server first. The script drops and recreates the schema, and the server rebuilds the tables at startup.

```powershell
./scripts/reset-server-db.ps1 -Database rc_soar_score -Port 5432
./scripts/reset-server-db.ps1 -Docker
```

```bash
bash scripts/reset-server-db.sh
bash scripts/reset-server-db.sh --docker
```

- With no container configured, the script uses local `psql`. `-Docker` / `--docker` uses the Compose `db` service. Set `POSTGRES_CONTAINER` (or PowerShell's `-Container NAME`) to use a named running container.
- `DATABASE_URL` takes precedence and must include the database name. Otherwise use `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_USER`, and `POSTGRES_PASSWORD`. PowerShell also accepts `-PgHost`, `-Port`, `-Database`, and `-User`.
- `-Force` / `--force` bypasses the localhost guard.

### [add-results-indexes.sql](./add-results-indexes.sql) — PostgreSQL

Adds the results-related indexes introduced in #843 to an existing PostgreSQL database. The statements run in one transaction and use `IF NOT EXISTS` so they can be reapplied. Fresh or reset databases already receive the indexes.

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/add-results-indexes.sql
```

In PowerShell, pass `$env:DATABASE_URL` in place of `"$DATABASE_URL"`.

## Release, licensing, and data model

### [generate_release_notes.py](./generate_release_notes.py) — Python

Finds pull requests merged since the previous published GitHub release and summarizes them with Claude. Falls back to GitHub-generated notes if the model call fails. Updates the release body while preserving the hand-written introduction above the marker.

```bash
python scripts/generate_release_notes.py RELEASE_TAG --dry-run
```

Pass a published release tag. `--dry-run` prints the result without updating GitHub. Requires Python 3 and the `gh` CLI with `GH_TOKEN` and `GITHUB_REPOSITORY` configured. Set `ANTHROPIC_API_KEY` for Claude and optionally `RELEASE_NOTES_MODEL` to override the model.

### [generate-licences.ps1](./generate-licences.ps1) / [generate-licences.sh](./generate-licences.sh) / [generate_licences.dart](./generate_licences.dart) — PowerShell + Bash, or direct Dart

Regenerates `apps/soar_score_web/src/content/licences.json` from the Dart and npm lockfiles and installed dependency licence texts. Run `dart pub get` (or `melos bootstrap`) and `npm ci` in `apps/soar_score_web` for the npm dependencies before generating.

```powershell
./scripts/generate-licences.ps1 --check
```

```bash
bash scripts/generate-licences.sh --product contest-app --notices THIRD_PARTY_NOTICES.txt
dart scripts/generate_licences.dart --product contest-app --json contest-licences.json
```

All three entry points accept the same options. Run with no options to regenerate the site's JSON. Use `--check` to fail if that JSON lags the lockfiles (not run in CI; releases regenerate it). Use `--product ID` with `--notices FILE`, `--json FILE`, or both for per-product output. Product IDs are `contest-app`, `self-scoring`, `server`, and `public-site`.

### [generate-enum-catalog.ps1](./generate-enum-catalog.ps1) — PowerShell

Generates `plan/data-model/enumerations.md` from entity field definitions and marks enum columns in `plan/data-model/ERD.md`. Use `-Check` to check for stale output or mismatches without writing files.

```powershell
./scripts/generate-enum-catalog.ps1
./scripts/generate-enum-catalog.ps1 -Check
```

### [verify-data-model-examples.ps1](./verify-data-model-examples.ps1) — PowerShell

Checks that every documented entity has a JSON example and that each example's top-level keys match its documented fields. Takes no options.

```powershell
./scripts/verify-data-model-examples.ps1
```

### [fix-headers.ps1](./fix-headers.ps1) — PowerShell

Normalizes Markdown line breaks in the metadata headers under `plan/data-model/entities/`. Takes no options and exits with code 1 when it rewrites files.

```powershell
./scripts/fix-headers.ps1
```

### [scrub_gliderscore_pilots.dart](./scrub_gliderscore_pilots.dart) — Dart

Generates anonymized GliderScore import fixtures from a Pilots JSONL export produced by `mdb-json`. The first two arguments are the pilot export and output directory. Optionally pass a third argument pointing at a directory with `Comps.jsonl`, `CompPilots.jsonl`, `Roles.jsonl`, `Dur.jsonl`, and `DBParams.jsonl` to generate competition fixtures too.

```bash
dart scripts/scrub_gliderscore_pilots.dart pilots.jsonl packages/soar_score_core/test/fixtures/gliderscore
dart scripts/scrub_gliderscore_pilots.dart pilots.jsonl packages/soar_score_core/test/fixtures/gliderscore comps
```

## Supporting files

- `e2e-contest-hosted.txt` and `e2e-contest-publishing.txt` list Contest E2E test filenames.
- `licence-overrides.json` and `licence-texts/` supply overrides and bundled licence text for the licence generator.
