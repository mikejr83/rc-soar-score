# Ticket 027 — Contest administration home route and shell

- **Category:** UI
- **Priority:** High
- **Status:** Open

## Context

Establish the `/contest-administration/home` route and the director's contest-selection page shell. After signing in or choosing offline mode, the user lands here. This ticket wires the route, provides the page title and layout structure for the contest list and actions, and links into the shell navigation.

## Work Items

- [ ] Add route `/contest-administration/home` to the app router
- [ ] Navigate to this route after successful sign-in and offline-mode selection
- [ ] Build the page shell with title "Contest administration"
- [ ] Set up layout regions for: contest list, row selection, actions (open/create/delete), and management navigation
- [ ] Add shell navigation entry for Contest administration

## Acceptance Criteria

- [ ] After sign-in or offline selection, the user lands on `/contest-administration/home`
- [ ] Page title "Contest administration" is displayed
- [ ] Layout provides a contest list region, action button region, and management navigation region
- [ ] Shell navigation includes a Contest administration item that routes here
- [ ] No crash on initial load; empty list region shows a placeholder or nothing

## Dependencies

- [020-contest-landing-page-route.md](020-contest-landing-page-route.md)
- [021-sigin-create-account-stubs.md](021-sigin-create-account-stubs.md)

## Sources

- `plan/ui/contest-administration/main-page.md`
