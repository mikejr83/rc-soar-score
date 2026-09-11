# RC Soar Score Public Site UI - Documentation and Help

This page displays the documentation and help for the RC Soar Score application and public web site.

The terms "documentation", "docs", and "help" are often used interchangeably within this document. The document attempts to convey that these pages are providing documentation to a user on how to perform various actions within the application and site. This appears semantically as providing "help" to the user. The UI implementation my not use the exact terminology as presented here unless specifically noted.

## Pages

The following sections list the pages found in the documentation and help portion of the public site.

A specialized "Page Not Found" page should be shown if the user attempts to navigate to a route that is beneath the `/docs` route. The application should redirect the user to the "Page Not Found" route.

### Index / Landing Page

Route: `/docs`

This page is the landing page for all documentation and user help.

The page will present some basic tips on getting started plus the following navigation items:

* Offer to register - Send the user to register for a user account at the identity provider.
* Link to download the offline application
* Link to contest search
* A "Contest Director Getting Started" link to the competition help landing page.
* A "Help Me Enter My Score" link to the participant scoring help page.
* A "I Need An Account?" link to the user account help page.
* A "Finding Contests and Results" link to the public contests help page.
* Request Support - On the landing page this can be just a navigation element to the support page.
* A space should be reserved for the future inclusion of a FAQ section.

### Competition Help

Route: `/docs/competitions`

This page will contain help and documentation for contest administrators to use the offline and web applications.

The page will include a main section that details the use of the application as if the contest director was performing all actions on the web site. A follow-up section would detail the differences on using the offline application. The offline section will detail the features specific to the offline application and the limitations of its use.

### Participant Scoring Help

Route: `/docs/participant-scoring`

This page will contain help and documentation for directed to users that are participants in a contest and will be entering scores.

The page will include a section that explains the overall goals of participant scoring. It will discuss the various options a contest director may select that would affect their use and what they see in participant scoring.

This page should use an example contest scoring scenario and walk the user through entering the score. Screen captures of each step should show how a score is entered for a typical contest.

The page should explain how participants may request score reviews if the contest director has enabled the feature. The page will explain each step and use screen captures to help the user follow along in the flow.

A sub-page should be created for each contest discipline. The user will select a contest discipline and be navigated to that page's specific help section. Each of these pages will contain a screen capture of the participant score entry screen with the default configuration for the discipline. A brief summary of the fields is included. These pages are not meant to be information dense and are used for quick review.

The sub-pages will have routes following this scheme: `/docs/participant-scoring/disciplines/<discipline-name>`. The `<discipline-name>` value in the route is not a dynamic parameter. Instead it is a placeholder value that represents a static page which will need to be created for each specific discipline as it is supported in the application. Thus, the initial release of the application will contain a page for the F5J discipline at `/docs/participant-scoring/disciplines/f5j` and it will be to a physical page. A future discipline, F3F, will have its page created at the time the application supports the discipline.

### User Account Help

Route: `/docs/user-accounts`

### Public Contests Help

Route: `docs/contests-and-scores`

### Not Found

Route: `docs/not-found`

This is a specialized page for users attempting to navigate to a route beneath the `/docs` route and it not existing. This page is separated from a site-wide "not found" page because it should attempt to help the user find documentation and help specific pages.

The main navigation elements presented on the documentation and help landing pages should be presented here. The layout may differ but the actual navigation aspects should be used.

The support link should differ than how the landing page requirements specify the inclusion of a link to the support page. When placing the navigation elements for this page. A prominent section of the page should show text "Are you having trouble?" as a large heading. Under it there should be text "If you have questions on functionality, are seeing errors, or have feature requests please go to our support page." A link should appear to take the user to the support page.

The support page documentation can be found at [`support.md`](./support.md).
