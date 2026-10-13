# Environment Setup

How to get a development machine ready to build, run, and test Soar Score. The
repo is a Dart/Flutter monorepo managed by [Melos](https://melos.invertase.dev/)
using Dart pub workspaces.

## 1. Required tools

| Tool    | Version                 | Notes                                          |
| ------- | ----------------------- | ---------------------------------------------- |
| Flutter | 3.47.x (stable channel) | Bundles Dart (3.13.x). Root SDK is `^3.13.3`.  |
| Melos   | 8.x (`^8.9.0`)          | Installed globally, or via `dart run melos`.   |
| Git     | any recent              |                                                |
| Chrome  | current                 | Target for `flutter run -d chrome` (web apps). |

The pins are recorded in
[`plan/tickets/mvp-implementation/001-setup-toolchain-baseline.md`](../plan/tickets/mvp-implementation/001-setup-toolchain-baseline.md),
which is the source of truth. If this page and that ticket disagree, the ticket
wins.

Optional tools:

| Tool                                                | Needed for                                                        |
| --------------------------------------------------- | ----------------------------------------------------------------- |
| PostgreSQL 14+ / Docker                             | Running the API server and its integration tests (see section 4). |
| Node.js (for `npx`)                                 | Markdown formatting with Prettier (see section 6).                |
| PowerShell 7+                                       | `scripts/verify.ps1` (the all-in-one check script).               |
| Visual Studio 2022 ("Desktop development with C++") | `flutter run -d windows` for the contest desktop shell.           |

## 2. Install the toolchain

### Flutter

Follow https://docs.flutter.dev/get-started/install for your OS, then pick the
stable channel and confirm the version line:

```bash
flutter channel stable
flutter upgrade
flutter --version   # expect Flutter 3.47.x, Dart 3.13.x
flutter doctor      # resolve anything it flags for the targets you use
```

Make sure the Flutter `bin` directory is on your `PATH` so both `flutter` and
`dart` resolve.

### Melos

```bash
dart pub global activate melos 8.9.0
```

Add the pub cache bin directory to your `PATH` so `melos` is found:

- Windows: `%LOCALAPPDATA%\Pub\Cache\bin`
- macOS/Linux: `$HOME/.pub-cache/bin`

Melos is also a root `dev_dependency`, so `dart run melos <command>` works
without the global install.

## 3. Clone and bootstrap

```bash
git clone https://github.com/mikejr83/rc-soar-score.git
cd rc-soar-score
melos bootstrap
```

`melos bootstrap` runs `pub get` across the workspace and links the path-based
packages in `packages/` into each app. Re-run it after pulling changes that
touch any `pubspec.yaml`.

Some packages use code generation (`json_serializable`, `drift`). If generated
files such as `*.g.dart` are missing or stale, regenerate them from the package
that owns them:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 4. Configure the API server

The server (`apps/soar_score_server`) needs a PostgreSQL database. It exits at
startup if `POSTGRES_PASSWORD` is not set.

### Environment variables

The server loads variables from the process environment and from a `.env` file
(`.env` and `.env.*` are git-ignored; never commit them).

| Variable            | Default         | Purpose                                                  |
| ------------------- | --------------- | -------------------------------------------------------- |
| `POSTGRES_PASSWORD` | none (required) | Database password. Unset means "not configured".         |
| `POSTGRES_HOST`     | `localhost`     | Database host.                                           |
| `POSTGRES_PORT`     | `5432`          | Database port.                                           |
| `POSTGRES_DB`       | `rc_soar_score` | Database name.                                           |
| `POSTGRES_USER`     | `postgres`      | Database user.                                           |
| `POSTGRES_SSLMODE`  | `disable`       | One of `disable`, `require`, `verifyFull`.               |
| `PORT`              | `8080`          | HTTP port the server listens on.                         |
| `AUTH0_DOMAIN`      | none            | Auth0 tenant used to fetch JWKS for JWT checks.          |
| `API_AUDIENCE`      | none            | Expected JWT audience (`https://soar-score.com/server`). |

A minimal local `.env` at the repo root:

```dotenv
POSTGRES_PASSWORD=choose-a-local-password
```

### Local PostgreSQL with Docker

```bash
docker run --name soar-score-db -d -p 5432:5432 \
  -e POSTGRES_PASSWORD=choose-a-local-password \
  -e POSTGRES_DB=rc_soar_score \
  postgres:16
```

Use the same password in `.env`. Any local PostgreSQL install works equally
well; just set the matching `POSTGRES_*` variables.

Handler tests (`dart test` in `apps/soar_score_server`) run in memory and do not
need a database. Integration tests in `packages/soar_score_data` are skipped
unless `POSTGRES_PASSWORD` is set.

### Auth0

Every `/api/v1/*` request except `/health` is validated against an Auth0 JWT.
For anything beyond unit tests, set `AUTH0_DOMAIN` and `API_AUDIENCE` to a
tenant/API you control. The development tenant is `dev-2qpi7354ddlhe45g`; the
API identifier (the audience) is `https://soar-score.com/server`.

#### Contest app sign-in

The contest app signs in with Auth0's Universal Login through `auth0_flutter`
(`lib/auth/`). The tenant domain, client IDs and audience are public
identifiers, so the development values are the defaults in
`lib/auth/auth_config.dart`. Override them with `--dart-define` for another
tenant or a release build: `AUTH0_DOMAIN`, `AUTH0_WEB_CLIENT_ID`,
`AUTH0_WINDOWS_CLIENT_ID`, `AUTH0_AUDIENCE` and `AUTH0_WINDOWS_SCHEME`.

The dashboard settings are listed in [Auth0 Setup](auth0-setup.md). In short, the web application (type Single Page Application)
needs the app origin, with a trailing slash, in Allowed Callback URLs, Allowed
Logout URLs and Allowed Web Origins (for example `http://localhost:5000/` when
running with `--web-port 5000`). The Windows application (type Native) needs
`com.soarscore.contest://callback` in Allowed Callback URLs and Allowed Logout
URLs. The audience API needs Allow Offline Access turned on.

The Windows build also needs:

1. [vcpkg](https://vcpkg.io/) with the plugin's native dependencies, and
   `VCPKG_ROOT` set before building:

   ```powershell
   git clone https://github.com/microsoft/vcpkg
   .\vcpkg\bootstrap-vcpkg.bat
   $env:VCPKG_ROOT = "$PWD\vcpkg"
   .\vcpkg\vcpkg.exe install --recurse "cpp-httplib[core,openssl]:x64-windows" nlohmann-json:x64-windows openssl:x64-windows
   ```

2. The `com.soarscore.contest` URL scheme registered for your user, so Windows
   returns the browser's callback to the app. For a development build, save
   this as a `.reg` file (with the path to your built `soar_score_contest.exe`)
   and run it. An installer registers the same keys.

   ```reg
   Windows Registry Editor Version 5.00

   [HKEY_CURRENT_USER\Software\Classes\com.soarscore.contest]
   @="URL:RC Soar Score"
   "URL Protocol"=""

   [HKEY_CURRENT_USER\Software\Classes\com.soarscore.contest\shell\open\command]
   @="\"C:\\Path\\To\\soar_score_contest.exe\" \"%1\""
   ```

## 5. Run the apps

Start the server first; the Flutter apps default to
`http://localhost:8080` and accept an override through
`--dart-define=SOAR_SCORE_API_BASE_URL=<url>`.

```bash
# API server
cd apps/soar_score_server
dart run lib/main.dart
```

```bash
# Contest management app (web)
cd apps/soar_score_contest
flutter run -d chrome --dart-define=SOAR_SCORE_API_BASE_URL=http://127.0.0.1:8080
```

```bash
# Contest management app (Windows desktop)
flutter run -d windows
```

```bash
# Public results site
cd apps/soar_score_public
flutter run -d chrome
```

```bash
# Participant self-scoring app
cd apps/soar_score_self_score
flutter run -d chrome
```

In VS Code, `.vscode/launch.json` already has launch configurations for the
server and each app (the contest web app is pinned to `127.0.0.1:8091`).

## 6. Verify your setup

```bash
melos analyze     # static analysis across the workspace
melos test        # all unit and widget tests
melos run build   # flutter build web for apps, dart compile exe for the server
```

On Windows, `scripts/verify.ps1` runs bootstrap, format check, analyze, test,
and build in one pass and exits non-zero on any failure:

```powershell
./scripts/verify.ps1
```

### Markdown formatting

Markdown must conform to the repo's Prettier config (`.prettierrc`). After
editing any `.md` file:

```bash
npx prettier --write <file>
npx prettier --check "**/*.md"
```

## 7. Troubleshooting

| Symptom                                              | Fix                                                                                              |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| `melos: command not found`                           | Add the pub cache `bin` directory to `PATH`, or use `dart run melos`.                            |
| `flutter --version` is not 3.47.x                    | `flutter channel stable && flutter upgrade`.                                                     |
| Server prints `POSTGRES_PASSWORD is not set`         | Set it in `.env` or your shell, and make sure PostgreSQL is reachable.                           |
| Pub resolution error mentioning `.plugin_symlinks`   | Workspace globs are intentionally first-level only; do not widen `workspace:` in `pubspec.yaml`. |
| Missing `*.g.dart` files / undefined generated types | Run `dart run build_runner build --delete-conflicting-outputs` in the affected package.          |
| `flutter run -d windows` fails to build              | Install Visual Studio with the C++ desktop workload and re-run `flutter doctor`.                 |

## Further reading

- [`README.md`](../README.md): project overview and architecture
- [`AGENTS.md`](../AGENTS.md): conventions, linting, and CI expectations
- [`plan/`](../plan/INDEX.md): business, architecture, and UI requirements
