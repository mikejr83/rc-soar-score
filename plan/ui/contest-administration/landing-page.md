# RC Soar Score User Interface - Landing Page

The online and desktop applications share the landing page structure. The page provides:

- `Sign in`, which navigates to the configured identity provider and returns to the application after authentication.
- `Create account`, which navigates to the identity provider registration flow.
- `Continue offline` in the desktop application.
- Links to help and the public contest site.

The desktop application must allow offline continuation without an account. It must state that offline contests remain local unless the director later publishes them or signs in to enable synchronization. If the local store cannot be opened, show the reason and a recovery action rather than entering the application with partial data.

The online application does not show `Continue offline`. An authenticated user is taken to the contest selection page. Participant invitation links do not use this landing page: they open the participant self-scoring app (`soar_score_self_score`), which validates the invitation and shows the participant overview described in [participant-scoring.md](../participant-scoring/participant-scoring.md).

The page has loading, identity-provider unavailable, and offline-store unavailable states. External navigation is visibly identified and does not silently discard local work.

## Route Information

The landing page for the application in the web app will be `/contest-administration`.
