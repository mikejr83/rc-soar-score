# Ticket 020 — Contest administration landing page (route and shell)

- **Category:** UI
- **Priority:** High
- **Status:** Done

## Context
This ticket establishes the landing page route and persistent shell layout for the contest administration experience. The landing page is the default entry point for both online and desktop users, providing Sign in / Create account actions, Continue offline (desktop only), and links to help and the public contest site.

## Work Items
- [x] Add root route `/contest-administration` for the contest-administration app
- [x] Create persistent shell layout: title area, breadcrumb/back navigation, main navigation, content area, status bar
- [x] Wire routing so `/contest-administration` renders the landing page content
- [x] Set up navigation guards for routes beyond the landing page (deferred to later tickets with real auth; named `navigationGuard` seam added to `GoRouter.redirect`, anonymous access currently allowed, unknown paths fall back to landing)

## Acceptance Criteria
- [x] The root route `/contest-administration` loads the landing page shell
- [x] Navigation guards allow anonymous access to the landing page
- [x] Shell layout follows the structure in `plan/ui/contest-administration/landing-page.md`
- [x] Browser back navigation works correctly

## Implementation Notes
- The navigation guard allows anonymous access to the landing page (`/contest-administration`).
- The navigation guard is inactive for routes beyond the landing page when the user is in offline mode (`AppModeNotifier.isOfflineMode == true`).
- When not in offline mode (and unauthenticated), attempting to access routes beyond the landing page redirects to `/contest-administration`.
- Unknown paths fall back to the landing page so browser back never lands on a dead URL.
- The app tracks offline mode state via `AppModeNotifier` and `AppModeInherited` in `app_mode_provider.dart`, which also notifies `GoRouter.refreshListenable` upon state transitions.
- Offline mode and `AppModeNotifier` are native desktop features; all instantiation and router guards are guarded by `!kIsWeb` so the mode notifier is tree-shaken out when compiled for web.

## Dependencies
- [004-scaffold-contest-flutter-app.md](004-scaffold-contest-flutter-app.md) — contest app routing
- [009-scaffold-ui-package.md](009-scaffold-ui-package.md) — theme tokens

## Sources
- `plan/ui/contest-administration/README.md`
- `plan/ui/contest-administration/landing-page.md`