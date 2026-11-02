# Auth0 Setup

What to configure on the Auth0 side so the apps and the server can sign people
in. The values below are the defaults the code expects. Where a value differs
(another tenant, another port), override it in the build as described in
[Environment Setup](environment-setup.md#contest-app-sign-in).

None of these values is a secret. There is no client secret anywhere: the web
app and the Windows app use the authorization code flow with PKCE, and the
server only verifies tokens against the tenant's public keys.

## Values at a glance

| Setting            | Development value                                        |
| ------------------ | -------------------------------------------------------- |
| Tenant             | `dev-2qpi7354ddlhe45g`                                   |
| Tenant domain      | `login.rcsoarscore.com`                                  |
| API identifier     | `https://soar-score.com/server`                          |
| Web client ID      | `ALL8oKywE1J31NEKvcaypfSeZSsoDXII`                       |
| Windows client ID  | `3FdIOOxNr4DF4iT8BDaqKWc9NabpEKbz`                       |
| Windows URL scheme | `com.soarscore.contest` (callback `<scheme>://callback`) |

The tenant domain is on the tenant's Settings page. The region part (`us`) is
an assumption in the code; if it differs, set `AUTH0_DOMAIN` in the build and
the server.

## 1. API (the audience)

Applications, APIs, Create API (or edit the existing one).

| Setting                       | Value                                                             |
| ----------------------------- | ----------------------------------------------------------------- |
| Name                          | `Soar Score Server`                                               |
| Identifier                    | `https://soar-score.com/server` (an identifier, not a live URL)   |
| Signing algorithm             | RS256                                                             |
| Allow Offline Access          | On (the apps ask for refresh tokens)                              |
| RBAC and permissions in token | Off (access is decided by backend relationships, not Auth0 roles) |
| Access token lifetime         | The default is fine; both apps renew the session silently         |

The server needs the same identifier as `API_AUDIENCE` and the tenant domain
as `AUTH0_DOMAIN`.

## 2. Contest app, web

Applications, Create Application.

| Setting                | Value                                            |
| ---------------------- | ------------------------------------------------ |
| Name                   | `Soar Score Contest (Web)`                       |
| Type                   | Single Page Web Application                      |
| Client ID              | `ALL8oKywE1J31NEKvcaypfSeZSsoDXII`               |
| Allowed Callback URLs  | the app origins, each with a trailing slash      |
| Allowed Logout URLs    | the same as the callback URLs                    |
| Allowed Web Origins    | the same origins                                 |
| Allowed Origins (CORS) | the same origins                                 |
| Grant types            | Authorization Code, Refresh Token (not Implicit) |
| Refresh Token Rotation | On, with a reuse interval of a few seconds       |
| Connections            | The database connection and Google               |

App origins to list, in each of the URL fields above:

- Local development: `http://localhost:5000/` (run with `--web-port 5000`).
- Deployed: `https://app.<your-domain>/`.

The app returns to the origin root after signing in or out (the sign-in
callback is `<origin>/`, handled before the first frame), so the origin with a
trailing slash is the only path to list. Do not add wildcards to the
production tenant; Cloudflare Pages preview URLs are not supported for sign-in.

## 3. Contest app, Windows

| Setting                | Value                                                                    |
| ---------------------- | ------------------------------------------------------------------------ |
| Name                   | `Soar Score Contest (Desktop)`                                           |
| Type                   | Native                                                                   |
| Client ID              | `3FdIOOxNr4DF4iT8BDaqKWc9NabpEKbz`                                       |
| Allowed Callback URLs  | `http://localhost:47821/callback` and `com.soarscore.contest://callback` |
| Allowed Logout URLs    | `http://localhost:47821/logout` and `com.soarscore.contest://callback`   |
| Grant types            | Authorization Code, Refresh Token                                        |
| Refresh Token Rotation | On                                                                       |
| Connections            | The database connection and Google                                       |

### Callback page in the browser

Auth0 does not redirect straight to the app. The app starts a small listener on
`localhost:47821` for the length of a sign-in or sign-out (the intermediary
server pattern of `auth0_flutter`). Auth0 sends the browser to
`http://localhost:47821/callback`; that page says "You can now close this browser
window" and hands the callback on to `com.soarscore.contest://callback`, which
Windows delivers to the running app. Sign-out works the same way through
`/logout`. The listener is separate from the embedded API (which stays on a
random port), binds to loopback only, serves nothing else, and only ever
forwards to the app's scheme (`lib/server/auth_callback_server.dart`).

Auth0 accepts exact callback URLs only, so the port is fixed
(`Auth0Config.windowsCallbackPort`); change it together with the two URLs above.
If another program holds the port, sign-in stops with a message saying so. The
two `com.soarscore.contest://callback` entries stay because the app still
receives the forwarded callback on that scheme.

The scheme is fixed in code, not a build setting. It must match
`Auth0Config.defaultWindowsScheme` (`lib/auth/auth_config.dart`), the constants
in `windows/runner/main.cpp`, and the registry entry. The app writes that entry
for the current user before sign-in, and an installer may write it too (see
Environment Setup); change all of them together. What an installer must register is in
[Windows Installer Requirements](windows-installer-requirements.md). "Continue offline"
never contacts Auth0.

### Session renewal

`auth0_flutter` has no token renewal on Windows, so the app renews the session
itself: when the access token expires it exchanges the stored refresh token at
`https://<tenant domain>/oauth/token` (grant `refresh_token`, client ID only).
This needs the application's grant types to include Refresh Token, and Refresh
Token Rotation on works as expected: the app stores the new refresh token from
every response. The session ends, with a notice on the landing page, only when
Auth0 refuses the refresh token (revoked, expired, or reused). Being offline or
an Auth0 outage does not end it; the next request tries again.

## 4. Connections

Authentication, Database: keep `Username-Password-Authentication` on and leave
sign-ups enabled, since registration is part of the product ("Create account"
opens the sign-up screen). For Google, the Auth0 development keys are fine on
the development tenant. Create your own Google OAuth client before release;
Auth0's shared keys are not for production. Then open each application's
Connections tab and switch the connections on.

## Who can do what

Auth0 only proves who the caller is. It does not decide what they may do. RBAC
is off on the API, so tokens carry no roles or permissions, and there is no
role-to-scope mapping to maintain. The server decides access from relationships
in its own data, looked up for the account behind the token:

- **Director.** The account that owns a contest. Only the owner may change the
  contest, its pilots, draw, scores and publication; anyone else gets 403
  `not_director`. The director's pilot list is their own private copy; a pilot's
  account never changes it.
- **Pilot.** A participant in a contest, linked to an account by invitation, by
  a director copying a listed pilot, or by the pilot confirming "Is this you?".
  A pilot can end a link; that never changes anything already published. The
  full model is in the agreed participants and accounts design (issues #149,
  #545).
- **Helper and guest scorers.** Scoring access for helpers and self-scoring
  participants follows the same rule: it comes from the participation record,
  not from a token claim.

Public results are different: `/public/*` reads need no sign-in, and the route
list is in [Environment Setup](environment-setup.md#auth0). Which relationships
the server enforces today grows with the account tickets under #169; this page
states the principle, the code and tickets state the current rules.

## Sign-in decisions

- **Contest app (web and Windows):** signs in with Auth0. "Continue offline" on
  Windows never contacts Auth0.
- **Self-scoring app (`score.rcsoarscore.com`):** signs in with Auth0, using its
  own Single Page Web Application (section 5). Wiring is tracked under #140.
- **Public site (`rcsoarscore.com`):** does not sign in. Results are anonymous
  reads of the public API.

## 5. Not needed yet

- A custom login domain. It changes the token issuer, and the issuer is part of
  every account identity, so decide before release.
- The self-scoring app, which is not wired to sign-in yet. When it is, create a
  second Single Page Web Application the same way as the contest web app.
- A post-login Action adding name and email to the access token. The server
  ticket (#148) decides between that and calling `/userinfo`.
- A production tenant. Repeat sections 1 to 4 in it before release and keep its
  identifiers out of the development defaults. Create your own Google OAuth
  client for it and settle the custom login domain first (tracked in release
  readiness, #157).

## Checking it

1. Run the contest app (`flutter run -d chrome --web-port 5000`) and choose
   Sign in. You should reach Universal Login and come back to the landing page
   with "Signed in as ...".
2. In the API's Test tab or a decoded access token, check that `iss` is
   `https://<tenant domain>/` and `aud` includes
   `https://soar-score.com/server`.
3. Sign out and confirm the browser lands on an allowed URL, not an Auth0
   error page. A "callback URL mismatch" error means the origin is missing from
   the lists in section 2 or 3.
