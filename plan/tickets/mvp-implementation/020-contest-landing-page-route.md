# Ticket 020 — Contest administration landing page (route and shell)

- **Category:** UI
- **Priority:** High
- **Status:** Open

## Context
This ticket establishes the landing page route and persistent shell layout for the contest administration experience. The landing page is the default entry point for both online and desktop users, providing Sign in / Create account actions, Continue offline (desktop only), and links to help and the public contest site.

## Work Items
- [ ] Add root route `/contest-administration` for the contest-administration app
- [ ] Create persistent shell layout: title area, breadcrumb/back navigation, main navigation, content area, status bar
- [ ] Wire routing so `/contest-administration` renders the landing page content
- [ ] Set up navigation guards for routes beyond the landing page

## Acceptance Criteria
- [ ] The root route `/contest-administration` loads the landing page shell
- [ ] Navigation guards allow anonymous access to the landing page
- [ ] Shell layout follows the structure in `plan/ui/contest-administration/landing-page.md`
- [ ] Browser back navigation works correctly

## Dependencies
- [004-scaffold-contest-flutter-app.md](004-scaffold-contest-flutter-app.md) — contest app routing
- [009-scaffold-ui-package.md](009-scaffold-ui-package.md) — theme tokens

## Sources
- `plan/ui/contest-administration/README.md`
- `plan/ui/contest-administration/landing-page.md`