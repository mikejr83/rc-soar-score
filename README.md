# RC Soar Score

![CI](https://github.com/mikejr83/rc-soar-score/actions/workflows/ci.yml/badge.svg)

**RC Soar Score** is an RC (radio-controlled) sailplane soaring contest scoring and management suite. It provides a comprehensive solution for contest directors, pilots, helpers, and soaring enthusiasts to organize, fly, score, and follow soaring competitions across multiple disciplines.

The system is designed for both connected and disconnected field operations, allowing contest directors to run events completely offline when remote flying fields have no internet connectivity, while offering seamless cloud synchronization and public result publishing when a connection is available.

---

## Table of Contents

- [Overview & Key Features](#overview--key-features)
- [Supported Soaring Disciplines](#supported-soaring-disciplines)
- [Repository Architecture](#repository-architecture)
  - [Applications (`apps/`)](#applications-apps)
  - [Shared Packages (`packages/`)](#shared-packages-packages)
  - [Layer Diagram](#layer-diagram)
- [Documentation & Planning](#documentation--planning)
- [Prerequisites & Toolchain](#prerequisites--toolchain)
- [Getting Started](#getting-started)
  - [Repository Setup](#repository-setup)
  - [Running the Applications](#running-the-applications)
  - [Building](#building)
  - [Running Tests & Linting](#running-tests--linting)
  - [End-to-End Tests (Contest App)](#end-to-end-tests-contest-app)
  - [Testing Against PostgreSQL](#testing-against-postgresql)
- [Conventions & Architecture Rules](#conventions--architecture-rules)
- [License](#license)

---

## Overview & Key Features

- **Offline-First & Cloud-Synced**: Full offline capability for contest directors at remote fields with SQLite persistence, paired with cloud synchronization to PostgreSQL when connectivity is established.
- **Flight Matrix Generator**: Automated round-and-group draw generator featuring simulated annealing optimization, team protection (preventing teammates from flying in the same group), and fairness distribution metrics.
- **Multiple Scoring Modes**:
  - _Official Scoring_: Fast, keyboard-friendly administrative entry and review by the contest director or local officials.
  - _Self-Scoring_: Mobile-first score entry portal for pilots and team helpers on their smartphones.
- **Public Results & Live Projections**: Dedicated public site for real-time leaderboards, round-by-round breakdown, landing stats, and contest archives.
- **Score Review & Dispute Workflow**: Structured audit trail for contested scores, reflights, penalties, and director score overrides.

---

## Supported Soaring Disciplines

RC Soar Score includes a domain scoring engine capable of handling standard soaring disciplines with their unique landing tapes, target windows, flight time truncation/rounding, penalties, and flight normalization:

| Discipline  | Description                                     | Rules & Specification                                                                                    |
| ----------- | ----------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| **ALES**    | Altitude Limited Electric Soaring               | [`plan/business-requirements/disciplines/ales.md`](plan/business-requirements/disciplines/ales.md)       |
| **F5J**     | Electric Motor Gliders with Altimeter Recording | [`plan/business-requirements/disciplines/f5j.md`](plan/business-requirements/disciplines/f5j.md)         |
| **F3J**     | Thermal Duration Gliders (Towline launch)       | [`plan/business-requirements/disciplines/f3j.md`](plan/business-requirements/disciplines/f3j.md)         |
| **Thermal** | Traditional Thermal Duration                    | [`plan/business-requirements/disciplines/thermal.md`](plan/business-requirements/disciplines/thermal.md) |
| **F3K**     | Hand-Launch Gliders (multi-task discipline)     | [`plan/business-requirements/disciplines/f3k.md`](plan/business-requirements/disciplines/f3k.md)         |
| **F3L**     | RES (Rudder, Elevator, Spoiler) 2m Gliders      | [`plan/business-requirements/disciplines/f3l.md`](plan/business-requirements/disciplines/f3l.md)         |

For discipline-wide scoring conventions, consult the [Discipline Scoring Architecture Guide](plan/architecture-requirements/discipline-scoring.md).

---

## Repository Architecture

RC Soar Score is structured as a Dart/Flutter monorepo managed with [Melos](https://melos.invertase.dev/).

```plain
soar-score/
├── apps/                        # End-user applications and backend service
│   ├── soar_score_contest/      # Contest director management app (Flutter Web / Desktop)
│   ├── soar_score_web/          # Public site, docs & results portal (Next.js)
│   ├── soar_score_self_score/   # Mobile self-scoring app for pilots (Flutter Web/Mobile)
│   └── soar_score_server/       # Shelf-based backend REST API service (Dart)
├── packages/                    # Shared Dart & Flutter packages
│   ├── soar_score_core/         # Pure Dart domain models & scoring engine
│   ├── soar_score_data/         # Data persistence layer & repository implementations
│   ├── soar_score_api/          # Shared HTTP client, DTOs, and typed API errors
│   ├── soar_score_api_handlers/ # Shared shelf route handlers
│   └── soar_score_ui/           # Shared Flutter design tokens and UI components
├── plan/                        # System specifications, architecture, and requirements
└── AGENTS.md                    # Coding standards and AI agent guidelines
```

### Applications (`apps/`)

- [`soar_score_contest`](apps/soar_score_contest/): The contest director's command center. Used to configure contests, manage pilots, execute matrix draws, oversee official scoring, handle disputes, and manage offline/online synchronization. Runs on laptops and tablets (Flutter Web / Windows desktop shell).
- [`soar_score_web`](apps/soar_score_web/): Public web site (Next.js, TypeScript). Product information, documentation and help, support, and the published contest results.
- [`soar_score_self_score`](apps/soar_score_self_score/): Lightweight, mobile-optimized Flutter web interface designed for pilots and helpers entering flight scores directly from the field.
- [`soar_score_server`](apps/soar_score_server/): Dart backend server using [Shelf](https://pub.dev/packages/shelf). Validates Auth0 OIDC JWTs, handles REST API endpoints, orchestrates data sync, and serves public contest projections.

### Shared Packages (`packages/`)

- [`soar_score_core`](packages/soar_score_core/): **Pure Dart** domain models, scoring rules, matrix generation algorithms, and abstract repository interfaces. Contains zero UI or platform dependencies so rules execute identically on client and server.
- [`soar_score_data`](packages/soar_score_data/): Repository implementations supporting both local SQLite (offline via Drift ORM / `sqlite3`) and remote PostgreSQL/HTTP storage.
- [`soar_score_api`](packages/soar_score_api/): Client HTTP library providing strongly-typed DTOs, JSON serialization, and error handling for frontend Flutter apps.
- [`soar_score_api_handlers`](packages/soar_score_api_handlers/): Composable Shelf routing table and endpoint handlers shared between the standalone server and the local desktop embedded API.
- [`soar_score_ui`](packages/soar_score_ui/): Shared Flutter widgets, theme tokens, and Material 3 design elements shared across frontend apps.

### Layer Diagram

```plaintext
Flutter Apps (soar_score_contest, soar_score_self_score)
         │
         ▼
soar_score_ui (shared Flutter widgets & tokens)
         │
         ▼
soar_score_api (HTTP client & DTOs)
         │
         ▼
soar_score_api_handlers (shelf route handlers)
         │
         ▼
soar_score_core (pure Dart domain logic, scoring engine, repository interfaces)
         │
         ▼
soar_score_data (SQLite local offline ↔ PostgreSQL server-side)
```

---

## Documentation & Planning

The repository contains extensive business and architectural documentation under the [`plan/`](plan/) directory. Refer to [`plan/INDEX.md`](plan/INDEX.md) for the master index:

- **[Business Requirements](plan/business-requirements/):**
  - [Contest Concepts & Terminology](plan/business-requirements/contests.md)
  - [Contest Lifecycle & Phases](plan/business-requirements/contest-phases.md)
  - [Matrix Draw & Pilot Grouping](plan/business-requirements/contest-draw.md)
  - [Official Scoring](plan/business-requirements/contest-official-scoring.md) and [Self-Scoring](plan/business-requirements/contest-self-scoring.md)
  - [Score Review & Protests](plan/business-requirements/score-review-requests.md)
- **[Architecture Requirements](plan/architecture-requirements/):**
  - [Data Model & Entities](plan/architecture-requirements/data.md)
  - [Scoring Engine Invariants](plan/architecture-requirements/discipline-scoring.md)
  - [Offline Synchronization & Conflict Resolution](plan/architecture-requirements/offline-synchronization.md)
  - [Matrix Draw Engine Algorithm](plan/architecture-requirements/matrix-draw.md)
- **[User Interface Specifications](plan/ui/):**
  - [Contest Administration UI](plan/ui/contest-administration/README.md)
  - [Participant Scoring UI](plan/ui/participant-scoring/README.md)
  - [Public Portal UI](plan/ui/public-site/README.md)
- **[Implementation Plan](plan/implementation-plan.md):** Technology choices, roadmap, and delivery milestones.

---

## Prerequisites & Toolchain

The repository enforces pinned toolchain baselines defined in `plan/tickets/mvp-implementation/001-setup-toolchain-baseline.md` and [`AGENTS.md`](AGENTS.md):

- **Flutter**: `3.47.x` (stable channel)
- **Dart**: Bundled with Flutter (`^3.13.3` SDK constraint)
- **Melos**: `^8.9.0` (Dart monorepo tool)

For the full walkthrough (Flutter, Melos, PostgreSQL, environment variables, running and verifying), see [`docs/environment-setup.md`](docs/environment-setup.md).

To install Melos globally:

```bash
dart pub global activate melos 8.9.0
```

---

## Getting Started

### Repository Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/mikejr83/rc-soar-score.git
   cd rc-soar-score
   ```

### Environment Setup

1. The environment setup is now moved into [docs/environment-setup.md](docs/environment-setup.md).
2. **Bootstrap the Melos workspace:**

   ```bash
   melos bootstrap
   ```

   This resolves all dependencies and links path-dependent packages across `apps/` and `packages/`.

### Running the Applications

#### Contest Management App (Web / Desktop)

```bash
cd apps/soar_score_contest
flutter run -d chrome      # Run as web app
flutter run -d windows     # Run as Windows desktop shell
```

The Windows desktop build needs extra tooling beyond Flutter: Visual Studio 2022 with the "Desktop development with C++" workload plus the ATL component, vcpkg with the `auth0_flutter` native dependencies (`cpp-httplib`, `nlohmann-json`, `openssl`) and `VCPKG_ROOT` set, and the app's `com.soarscore.contest` URL scheme (registered automatically). See the "Windows build also needs" checklist in [`docs/environment-setup.md`](docs/environment-setup.md) for the exact install steps. No Android tooling is needed by any app today; all targets are web or the Windows shell.

##### Demo data (development only)

A fresh native install is empty. To explore the app with example data, run the native app in demo mode:

```bash
flutter run -d windows --dart-define=SOAR_SCORE_DEMO=true
```

- Demo mode uses its own database, `soar_score_demo.db`, beside the normal `soar_score.db` in the per-user application support folder (`%APPDATA%` on Windows). The normal database is never opened or changed, and the demo database is never used without the define.
- The first start with an empty demo database loads example data: 18 made-up pilots and five contests, one in each lifecycle state (Created, Configuring, Ready with a drawn matrix, Running with teams, and Completed). Later starts keep whatever is in the demo database, including your own changes.
- Add `--dart-define=SOAR_SCORE_DEMO_RESET=true` to delete the demo database first and load the example data again.
- No scores are loaded yet, because nothing in the app records them. The Running and Completed contests only have their state and drawn matrix.
- The defines are ignored in release builds and have no effect on web builds or the server.
- In VS Code, use the launch configurations **soar_score_contest (Windows, demo data)** and **(Windows, fresh demo data)**, or the tasks **contest app: run with demo data (Windows)** and **contest app: run with fresh demo data (Windows)**.

#### Public Site

```bash
cd apps/soar_score_web
npm install
npm run dev
```

#### Participant Self-Scoring App

```bash
cd apps/soar_score_self_score
flutter run -d chrome
```

#### API Server

The server reads its settings from environment variables and needs a
PostgreSQL database:

| Variable                                                                             | Meaning                                                                                                       | Default                                           |
| ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| `DATABASE_URL`                                                                       | libpq connection URL (`postgresql://user:password@host:port/db?sslmode=...`). Wins over `POSTGRES_*` when set | none, unless the `POSTGRES_*` variables are set   |
| `POSTGRES_PASSWORD`                                                                  | database password                                                                                             | required, unless `DATABASE_URL` is set            |
| `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_SSLMODE` | database connection                                                                                           | localhost, 5432, rc_soar_score, postgres, disable |
| `PORT`                                                                               | listening port                                                                                                | 8080                                              |
| `LOG_LEVEL`                                                                          | a `package:logging` level name                                                                                | INFO                                              |
| `LOG_FORMAT`                                                                         | `json` or `text`                                                                                              | json                                              |

```bash
cd apps/soar_score_server
POSTGRES_PASSWORD=... dart run lib/main.dart
DATABASE_URL='postgresql://user:password@host:5432/rc_soar_score?sslmode=require' dart run lib/main.dart
```

The `DATABASE_URL` form is what host providers hand out (for example Neon), and when it is set it wins over the `POSTGRES_*` variables. An absent `sslmode` means `require` TLS.

To run the server and a PostgreSQL database in containers (local development
only; the compose file uses a throwaway password unless you set
`POSTGRES_PASSWORD`):

```bash
docker compose up --build
curl http://localhost:8080/health
```

The image runs as a non-root user, holds no secrets, and checks its own
`/health` (`server --healthcheck`). CI builds it on every pull request and
pushes it to GitHub Container Registry from `master`.

### Building

Use Melos scripts defined in the root `pubspec.yaml`:

```bash
# Build all apps (Flutter web apps and Dart server executable)
melos run build

# Build only Flutter web apps
melos run build:web

# Compile Dart server executable
melos run build:dart
```

### Running Tests & Linting

```bash
# Run static analysis across all apps and packages
melos analyze

# Run unit tests across all projects
melos test
```

You can also run tests within an individual subproject:

```bash
cd packages/soar_score_core
dart test

cd apps/soar_score_contest
flutter test
```

### End-to-End Tests (Contest App)

The contest app's journeys live in `apps/soar_score_contest/integration_test/`. They run locally or from an agent, never in CI. Every test file starts from freshly seeded demo data.

```bash
./scripts/e2e.sh                                  # Windows desktop (default)
./scripts/e2e.sh -d web                           # headless Chrome (any OS)
./scripts/e2e.sh -d web -f score_entry_test.dart  # one test file
```

On PowerShell use `.\scripts\e2e.ps1`, with `-Device web` and `-File <name>`. On Windows desktop you can also add `-Name '<test name>'` (or `-- --name '<test name>'` for the shell script) to run one journey of a file; the web mode runs whole files, since `flutter drive` has no name filter.

The web mode builds the app with an always-signed-in session and runs it against `apps/soar_score_server/tool/e2e_server.dart`, a test-only API server on demo data that skips token checks. The scripts start and stop that server for each test file; it must never be deployed. The Windows mode needs the Windows desktop toolchain and a display. The web mode needs only Chrome and chromedriver, as follows.

**Set up Chrome and chromedriver (web mode)**

Run the setup script once. It downloads Chrome for Testing and the chromedriver of the same version (about 220 MB) into `.e2e-tools/` at the repo root, which git ignores, and does nothing if they are already there. Nothing is installed system-wide and no `PATH` change is needed: `e2e.sh -d web` and `e2e.ps1 -Device web` look in that folder first.

```bash
./scripts/e2e-setup.sh               # PowerShell: .\scripts\e2e-setup.ps1
./scripts/e2e-setup.sh --dry-run     # show what it would download
./scripts/e2e.sh -d web -f offline_contest_journey_test.dart
```

`--channel Beta` (or `-Channel`) and `--version <x.y.z.w>` (or `-Version`) pick another Chrome for Testing build. Re-run the script to update; old versions stay in `.e2e-tools/` until you delete it. On Linux, Chrome also needs its system libraries (on Debian or Ubuntu: `sudo apt-get install -y libnss3 libatk-bridge2.0-0 libgtk-3-0 libgbm1 libasound2`).

To use your own Chrome instead, install a chromedriver with the **same major version** (a mismatch fails with a session error), then put it on `PATH` or point the scripts at both binaries. The environment overrides `.e2e-tools/`:

```bash
export CHROMEDRIVER=/path/to/chromedriver            # PowerShell: $env:CHROMEDRIVER = '...'
export CHROME_EXECUTABLE=/path/to/chrome             # optional; Chrome is found automatically otherwise
```

There is no display to set up: the web mode runs Chrome headless (Flutter's `web-server` device), so it works on servers and in containers. If you need to see the browser while debugging, run a single file by hand with a visible Chrome:

```bash
# terminal 1: the test server
cd apps/soar_score_server && dart run tool/e2e_server.dart --port 18080

# terminal 2: chromedriver
chromedriver --port=4444

# terminal 3: the test file
cd apps/soar_score_contest
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/<file>_test.dart \
  -d web-server --browser-name=chrome --no-headless \
  --dart-define=SOAR_SCORE_E2E=true \
  --dart-define=SOAR_SCORE_API_BASE_URL=http://localhost:18080
```

The scripts exit at once when chromedriver is missing or does not answer on port 4444 (another instance may hold it). They also stop any test file that runs longer than `E2E_TEST_TIMEOUT` seconds (default 300) and count it as failed. A healthy file takes about a minute, so a run that is silent for much longer is hung. `E2E_SERVER_PORT` (default 18080) changes the test server's port. More in `apps/soar_score_contest/AGENTS.md`.

### Testing Against PostgreSQL

The data package (`packages/soar_score_data`) runs the same tests on SQLite and on PostgreSQL. SQLite is in memory and always runs. The PostgreSQL group runs only when a server is configured; otherwise it is reported as skipped. A skipped run is not a PostgreSQL pass.

To do it all in one step (needs Docker), run the script. It starts a throwaway container on `127.0.0.1:54329`, runs the data package tests against it, and removes the container even if the tests fail. Extra arguments after `--` go to `dart test`, and `-Port` changes the host port:

```bash
./scripts/test-postgres.ps1
./scripts/test-postgres.ps1 -- -n "unit of work"
```

CI runs the same flow with `scripts/test-postgres.sh` (a shell port of the
PowerShell script).

To manage the server yourself instead:

1. Start a throwaway PostgreSQL server, for example with Docker:

   ```bash
   docker run --name soar-pg -e POSTGRES_PASSWORD=dev -p 5432:5432 -d postgres:17
   ```

2. Tell the tests where it is. `POSTGRES_PASSWORD` turns the PostgreSQL group on; the rest are optional:

   | Variable            | Default      |
   | ------------------- | ------------ |
   | `POSTGRES_PASSWORD` | _(required)_ |
   | `POSTGRES_HOST`     | `localhost`  |
   | `POSTGRES_PORT`     | `5432`       |
   | `POSTGRES_USER`     | `postgres`   |
   | `POSTGRES_SSLMODE`  | `disable`    |

3. Run the data package tests:

   ```bash
   cd packages/soar_score_data
   POSTGRES_PASSWORD=dev dart test
   ```

Each test creates its own database (named `soar_test_...`) on the server and drops it afterwards, so the server's existing databases are untouched and the tests do not need a clean server. The connecting user needs permission to create and drop databases. Stop the server with `docker rm -f soar-pg`.

---

## Conventions & Architecture Rules

- **Path Dependencies**: All shared packages use relative path dependencies within `pubspec.yaml` to ensure monorepo consistency.
- **Separation of Concerns**: `soar_score_core` must never import Flutter or data-layer drivers; domain logic remains 100% pure Dart.
- **Code Style**: Follow rules defined in root and subproject `analysis_options.yaml`. Run `melos analyze` prior to committing.
- **Commit Messages**: Follow the [Conventional Commits](https://www.conventionalcommits.org) specification — `<type>(<scope>): <summary>` with types such as `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, etc. See [`AGENTS.md`](AGENTS.md#commit-messages) for the full rules.
- **Agent Guidelines**: See [`AGENTS.md`](AGENTS.md) for developer conventions, testing requirements, and subproject rules.

## License

Copyright (c) 2026 Mike Gardner.

RC Soar Score is licensed under the [GNU Affero General Public License v3.0](LICENSE) (AGPL-3.0). A modified version offered to users over a network must make its source available under the same licence. The planning and rule documentation (Markdown under `plan/`, `docs/` and `research/`) is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/); credit Mike Gardner and link to this repository when you reuse it. Published contest results remain the data of the contest director and participants and are not licensed by this project. Contributions need no sign-off beyond the licence terms. Decision record: [#218](https://github.com/mikejr83/rc-soar-score/issues/218).
