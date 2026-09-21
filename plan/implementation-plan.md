# RC Soar Score Implementation Plan

This document covers topics related to the implementation of the RC Soar Score applications.

## Repository Structure

This solution will be a monorepo. The repo will use NX workspaces. Each application will be located in the `apps/` folder. If it becomes appropriate to use shared packages, a `packages/` folder is to be created.

The `plan/` folder will remain to be a stable source of truth for the application design. Any questions regarding implementation from a business, architecture, or UI perspective should be directed to the documentation in this folder.

## Technologies

### Client Applications

The client applications will be written in Flutter. The overall UI design should follow Material 3 design requirements.

The contest management offline application will present display elements that are only applicable to it possibly running in a disconnected state. The application implementation will need to take this into consideration.

The contest manage application will be used mostly on laptops or tablets. The UI will need to be clear and concise to support this viewing method. The offline application should be presented to the user as a maximized window that efficiently uses all the available screen real estate. The web application version should be able to follow the same premise. Both of these applications can use similar navigation constructs.

The self-scoring application will function differently. It's main viewing environment will take place on mobile devices with smaller screens. The overall design of the application should remain with the Material 3 spec but more consideration should be given to the fact that the screens almost exclusively be accessed via a mobile browser.

The self-scoring web application should be separated from the other contest management application and the public web site. This is so that its Flutter implementation can include device specific implementations for mobile devices in the future (eg. an Android application is desirable in the future). The initial release is to be web only, however.

The public web site, the site for the RC Soar Score project and the contest results, should present itself both as a project web site complete with a landing page, documentation, help, and other application specific items as well as also being a designed to show the dense information that is presented with contest results. This may be an area where a departure from strict Material 3 design is acceptable. Data becomes very tabular and report like.

The goal for the initial release is to present the complete offline application, its web counterpart, the self-scoring web application, and the public site. This includes the following:

* All defined participant options should be implemented
* All scoring options should be implemented
* ALES, Thermal Duration, F3J, and F5J disciplines should be implemented.
* Offline sync
* Participant registration and syncing to local contest director data.
* Contest results view

### API Layer

The backend API layer is going to be written in Dart (shelf).

## Identity Provider

THe initial release of the applications will use Auth0 as its identity provider.

The API layer should use JWT to decode tokens and perform authn/authz. The client authentication should follow the OIDC Authorization Code + PKCE flow. The Flutter SDK for Auth0 should be used.

## Testing

### Unit testing

Each application should be set up with unit tests. These are key to the solution. Unit tests must be added for all new coded and should pass before any code is submitted for a PR. Commits with failing tests are acceptable but all test failures must be resolved before the code is accepted into a mainline branch. Unit tests are to be written in the appropriate test framework for each application.

### Integration Testing

Each of the client application should be tested via Playwright. This will provide feedback for integrated testing of the client and API layers.

## CI/CD

GitHub workflows will be created for building and testing the application. Additionally, a workflow for performing manual integration testing using Playwright is also to be included.
