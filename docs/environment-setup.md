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

| Tool                                                                        | Needed for                                                                                                        |
| --------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| PostgreSQL 14+ / Docker                                                     | Running the API server and its integration tests (see section 4).                                                 |
| Node.js (for `npx`)                                                         | Markdown formatting with Prettier (see section 6).                                                                |
| PowerShell 7+                                                               | `scripts/verify.ps1` (the all-in-one check script).                                                               |
| Visual Studio 2022 ("Desktop development with C++", plus the ATL component) | `flutter run -d windows` for the contest desktop shell.                                                           |
| vcpkg                                                                       | Native C++ dependencies (`cpp-httplib`, `nlohmann-json`, `openssl`) for the Windows desktop build; see section 2. |
| Android Studio (SDK, platform-tools, emulator)                              | Nothing is built for Android today; not required for web or Windows targets (see below).                          |

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

### vcpkg (Windows desktop builds)

The Windows desktop build pulls `cpp-httplib`, `nlohmann-json`, and `openssl`
through [vcpkg](https://vcpkg.io/) and requires `VCPKG_ROOT` to point at the
vcpkg checkout. Set it up once:

```powershell
# From the repo root, clone vcpkg alongside the app you will build
cd apps\soar_score_contest
git clone https://github.com/microsoft/vcpkg
.\vcpkg\bootstrap-vcpkg.bat
```

`bootstrap-vcpkg.bat` compiles (or downloads) `vcpkg.exe`. Then install the
three native dependencies the plugin needs. The `x64-windows` triplet matches
the desktop shell's architecture:

```powershell
.\vcpkg\vcpkg.exe install --recurse `
  "cpp-httplib[core,openssl]:x64-windows" `
  nlohmann-json:x64-windows `
  openssl:x64-windows
```

The first run builds the packages and can take several minutes; later runs are
fast.

Then make the CMake build see vcpkg. Either:

- For a single PowerShell session: set
  `$env:VCPKG_ROOT` to the vcpkg folder you cloned (its full path, no trailing
  backslash) before building, or
- Persistently (so it also applies when building from VS Code or another
  terminal): `setx VCPKG_ROOT <full path to the vcpkg folder>`, then close and
  reopen your shell or VS Code.

Two vcpkg-specific gotchas:

- The CMake toolchain is captured at first configure. If you change
  `VCPKG_ROOT` or install new packages, delete
  `apps\soar_score_contest\build\windows` (or run `flutter clean`) before
  building again, otherwise CMake keeps the old toolchain.
- `Could not find a package configuration file provided by "httplib"` means
  the vcpkg toolchain was not used — check `VCPKG_ROOT` and do the `flutter
clean` above.

### Android Studio

Not required to build or run anything in this repo today. No app has an
`android/` platform directory; every target is Web (Chrome) or the Windows
desktop shell, and `flutter run -d chrome` / `flutter run -d windows` need no
Android SDK.

Only install Android Studio if you will build a native Android app, which is
planned for the self-scoring app but not part of this release. In that case
install [Android Studio](https://developer.android.com/studio) (which bundles
the Android SDK, platform-tools, and the emulator), let `flutter doctor -a`
list the Android toolchain, and accept its licenses. Nothing in this repo needs
it in the meantime.

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

The server (`apps/soar_score_server`) needs a PostgreSQL database and the Auth0
tenant it accepts tokens from. It exits at startup, listing every problem, if
`POSTGRES_PASSWORD`, `AUTH0_DOMAIN` or `API_AUDIENCE` is not set.

### Environment variables

The server loads variables from the process environment and from a `.env` file
(`.env` and `.env.*` are git-ignored; never commit them).

| Variable               | Default         | Purpose                                                                                                            |
| ---------------------- | --------------- | ------------------------------------------------------------------------------------------------------------------ |
| `POSTGRES_PASSWORD`    | none (required) | Database password. Unset means "not configured".                                                                   |
| `POSTGRES_HOST`        | `localhost`     | Database host.                                                                                                     |
| `POSTGRES_PORT`        | `5432`          | Database port.                                                                                                     |
| `POSTGRES_DB`          | `rc_soar_score` | Database name.                                                                                                     |
| `POSTGRES_USER`        | `postgres`      | Database user.                                                                                                     |
| `POSTGRES_SSLMODE`     | `disable`       | One of `disable`, `require`, `verifyFull`.                                                                         |
| `PORT`                 | `8080`          | HTTP port the server listens on.                                                                                   |
| `AUTH0_DOMAIN`         | none (required) | Auth0 tenant host name, no scheme (`tenant.us.auth0.com`).                                                         |
| `API_AUDIENCE`         | none (required) | Expected JWT audience (`https://soar-score.com/server`).                                                           |
| `CORS_ALLOWED_ORIGINS` | none            | Comma-separated browser origins allowed to call the API, e.g. `http://127.0.0.1:8091`. Empty adds no CORS headers. |

A minimal local `.env` at the repo root:

```dotenv
POSTGRES_PASSWORD=choose-a-local-password
AUTH0_DOMAIN=dev-2qpi7354ddlhe45g.us.auth0.com
API_AUDIENCE=https://soar-score.com/server
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

Every `/api/v1/*` request needs `Authorization: Bearer <access token>`; `/health`
and the public `/public/*` reads do not. The server checks the token's RS256
signature against the tenant's public keys (`https://<AUTH0_DOMAIN>/.well-known/jwks.json`),
its expiry, its issuer (`https://<AUTH0_DOMAIN>/`) and that its audience is
`API_AUDIENCE`. A missing or bad token gets 401. The development tenant is
`dev-2qpi7354ddlhe45g`; the API identifier (the audience) is
`https://soar-score.com/server`.

The first request from a new sign-in creates a registered account. Access
tokens carry no name or email, so the server asks the tenant's `/userinfo`
endpoint once for them; it needs the app to have requested the `openid profile
email` scopes (the contest app does). Later requests only look the account up.

#### Contest app sign-in

The contest app signs in with Auth0's Universal Login through `auth0_flutter`
(`lib/auth/`). The tenant domain, client IDs and audience are public
identifiers, so the development values are the defaults in
`lib/auth/auth_config.dart`. Override them with `--dart-define` for another
tenant or a release build: `AUTH0_DOMAIN`, `AUTH0_WEB_CLIENT_ID`,
`AUTH0_WINDOWS_CLIENT_ID` and `AUTH0_AUDIENCE`. The Windows URL scheme is fixed in code.

The dashboard settings are listed in [Auth0 Setup](auth0-setup.md). In short, the web application (type Single Page Application)
needs the app origin, with a trailing slash, in Allowed Callback URLs, Allowed
Logout URLs and Allowed Web Origins (for example `http://localhost:5000/` when
running with `--web-port 5000`). The Windows application (type Native) needs
`com.soarscore.contest://callback` in Allowed Callback URLs and Allowed Logout
URLs. The audience API needs Allow Offline Access turned on.

`flutter run -d windows` needs four things beyond Flutter. Install all of
them before the first build:

1. Visual Studio 2022 with the **"Desktop development with C++"** workload.
   Flutter's Windows desktop toolchain (MSVC, CMake, and Ninja) ships with it.
   If `flutter doctor` does not list it, install it from
   https://visualstudio.microsoft.com/downloads/ and re-run
   `flutter doctor`.

2. The ATL component of Visual Studio, which `flutter_secure_storage` needs
   (`atlstr.h`). In Visual Studio Installer, Modify, Individual components,
   tick "C++ ATL for latest v143 build tools (x86 & x64)". Without it the
   build stops with `Cannot open include file: 'atlstr.h'`.

3. [vcpkg](https://vcpkg.io/) with the plugin's native dependencies and
   `VCPKG_ROOT` set before building. Full install steps — cloning,
   bootstrapping, installing `cpp-httplib[core,openssl]`, `nlohmann-json` and
   `openssl` for `x64-windows`, and setting the environment variable — are in
   the [vcpkg subsection of section 2](#vcpkg-windows-desktop-builds).

4. The `com.soarscore.contest` URL scheme, so Windows returns the browser's
   callback to the app. Nothing to do by hand: the app registers it for your
   user (under `HKEY_CURRENT_USER`, no administrator rights) just before
   sign-in, pointing at the running executable, so a development build works
   as is. Running a different build later, such as an installed copy, takes the
   scheme over the next time that build signs in. An installer should register
   the same keys; see
   [Windows Installer Requirements](windows-installer-requirements.md).

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
# Public site (Next.js; needs Node.js 24 and npm)
cd apps/soar_score_web
npm install
npm run dev
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

| Symptom                                              | Fix                                                                                                                                                                                                         |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `melos: command not found`                           | Add the pub cache `bin` directory to `PATH`, or use `dart run melos`.                                                                                                                                       |
| `flutter --version` is not 3.47.x                    | `flutter channel stable && flutter upgrade`.                                                                                                                                                                |
| Server prints `POSTGRES_PASSWORD is not set`         | Set it in `.env` or your shell, and make sure PostgreSQL is reachable.                                                                                                                                      |
| Pub resolution error mentioning `.plugin_symlinks`   | Workspace globs are intentionally first-level only; do not widen `workspace:` in `pubspec.yaml`.                                                                                                            |
| Missing `*.g.dart` files / undefined generated types | Run `dart run build_runner build --delete-conflicting-outputs` in the affected package.                                                                                                                     |
| `flutter run -d windows` fails to build              | See section 4: the Windows build needs Visual Studio C++ (plus ATL), vcpkg with the plugin's native dependencies and `VCPKG_ROOT` set, and the `com.soarscore.contest` URL scheme. Re-run `flutter doctor`. |

## Further reading

- [`README.md`](../README.md): project overview and architecture
- [`AGENTS.md`](../AGENTS.md): conventions, linting, and CI expectations
- [`plan/`](../plan/INDEX.md): business, architecture, and UI requirements
