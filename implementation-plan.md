# Plan: RC Sailplane Contest Soaring Application and Site

This repository will contain a monorepo for an application that helps contest directors score various types of radio controlled sailplane contests. The solution is characterized by its ability for contest directors to either access a web site via the internet where all actions are persisted through an API layer or through a local version of the application that can manage the whole contest and only sync back through the API when the user has internet access and wishes to do so. A separate web application is provided for public viewing of contests and scores. The solution will contain the following parts:

* Angular PWA used for situations where contest directors have access to the internet.
* Desktop shells (Electron primary, Tauri optional) for offline contest management.
* C# service API layer.
* Angular application for the public facing site containing the information about the software and the ability to view previous contests.

## Plan: Cross-platform Monorepo

TL;DR - Use an Nx-managed monorepo with `pnpm` for package management. Build a single Angular PWA as the canonical app for contest directors, add desktop shells (Electron primary, Tauri optional) that wrap the built web artifacts, and provide a Capacitor/Android path for Chromebook/Android containers where needed. Use GitHub Actions for CI, `electron-builder`/Tauri bundlers for desktop packaging, and host the PWA for web/Chromebook installs.

**Steps**
1. Initialize workspace: create `pnpm-workspace.yaml`, root `package.json`, and Nx workspace (`npx create-nx-workspace@latest` or `pnpm dlx create-nx-workspace`). (*blocks: none*)
2. Create core Angular app: `apps/web` as an Angular PWA using `@nx/angular` or `ng add @angular/pwa`. (*depends on step 1*)
3. Add shared libs: `libs/shared-ui`, `libs/shared-data`, `libs/core` and move reusable code into them. (*parallel with step 4*)
4. Add desktop shells: create `apps/desktop-electron` that builds the Angular `dist/` and loads it in Electron. Optionally create `apps/desktop-tauri` with Tauri config. (*depends on step 2*)
5. Add Chromebook/mobile path: create `apps/chromebook` which is either the same PWA or a Capacitor wrapper for Android runtime. Decide based on needed native APIs. (*parallel with step 4*)
6. Configure build targets: update Nx project targets for `build:web`, `build:electron`, `package:electron`, `build:tauri`, `package:tauri`, `build:capacitor`.
7. Security & runtime hardening: enable contextIsolation, disable nodeIntegration, enforce CSP, and audit native modules. (*depends on step 4*)
8. CI/CD pipelines: create GitHub Actions workflows for lint/test/build and per-platform packaging and release (including code-signing steps). (*depends on build targets*)
9. Packaging & releases: integrate `electron-builder` (Windows/macOS/Linux), Tauri bundling (optional), Flatpak/AppImage/Snap strategies for Linux, and macOS notarization. Automate artifact creation in CI. (*depends on step 8*)
10. Verification & user testing: manual/automated tests on each platform; set up auto-update channels and distribution (release notes, store uploads). (*depends on step 9*)

**Relevant files**
- **Workspace configs**: package.json, pnpm-workspace.yaml, nx.json, angular.json
- **TypeScript configs**: tsconfig.base.json, tsconfig.json, tsconfig.app.json
- **App roots**: apps/web/, apps/desktop-electron/, apps/desktop-tauri/ (optional), apps/chromebook/
- **Libs**: libs/shared-ui/, libs/shared-data/, libs/core/
- **Platform configs**: manifest.json, ngsw-config.json, capacitor.config.json, tauri.conf.json, electron-builder.json

**Verification**
1. Run `pnpm install` then `nx build web` and verify `dist/apps/web` contains the PWA bundle.
2. Run Electron in dev mode loading the local `dist` and verify app windows, CSP, and context isolation.
3. Produce CI artifacts for at least one platform (e.g., Windows .exe via `electron-builder`) and validate install/run.
4. Run Lighthouse on the PWA build and confirm offline caching/service worker functioning.

**Decisions**
- Recommended stack: **Nx + pnpm + Angular PWA + Electron** (primary). This leverages Angular expertise, offers mature desktop support, and keeps a single web code path.
- Alternative: **Angular PWA + Capacitor** if Chromebook Android runtime features are required and Electron-sized binaries are undesirable.
- Optional: **Tauri** if binary size and native performance are higher priorities than plugin maturity.

**Further Considerations**
1. Codesigning: obtain Windows Authenticode and macOS Developer ID certificates early to avoid release delays.
2. Native modules: prefer web-first APIs; if native Node modules are unavoidable, prepare rebuild scripts for Electron ABI compatibility.

