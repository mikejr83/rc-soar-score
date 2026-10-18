# RC Soar Score Public Site UI - Homepage

The public site for RC Soar Score will have a landing page which provides the overall details of what the application is and the services it provides.

The user should see any application logo along with text describing the application.

The page should contain the following navigation elements:

- Login / Registration - A link to the contest administration app, which signs the user in through the IdP. The public site has no sign-in of its own in the initial release; a profile area for any account holder (own placings, stats) is a later addition.
- Documentation / Help - Navigates the user to the documentation and help landing page - Route: `/docs`.
- Contests - Navigates to the contest search page - Route: `/results/contests`.

The homepage's location will be the "index" route for the site, ie it will be the root of all navigation. For preliminary purposes assume the domain rc-soar-score.com is used. Thus, the site's homepage is located at `https://rc-soar-score.com`.
