# Authentication Request Flow

This document maps how HTTP requests are authenticated in the Soar Score server, from the middleware down to database access.

## Call Chain

### 1. Server Startup — Auth Middleware Wires In

**File:** `apps/soar_score_server/lib/server.dart`

- Lines 99-101: `shelf_io.serve` calls `createServerHandler` with `authMiddleware: authMiddleware ?? _auth0Middleware(config, db)`
- Line 145: `_auth0Middleware` is defined (returns `bearerAuth(...)` at line 150)
- Lines 150-160: Builds `bearerAuth()` with `Auth0TokenVerifier` and `AccountPrincipalResolver`

```dart
return bearerAuth(
  verifier: Auth0TokenVerifier(
    domain: config.auth0Domain,
    audience: config.apiAudience,
  ),
  resolver: AccountPrincipalResolver(
    accounts: repository.accountRepository,
    identities: repository.accountIdentityRepository,
    profiles: Auth0UserProfileSource(domain: config.auth0Domain),
  ),
);
```

### 2. Handler Builds API Routing Tree

**File:** `packages/soar_score_api_handlers/lib/handler.dart`

- Lines 128-129: Wraps `/api/v1` subtree with auth middleware

```dart
api = authMiddleware(api);
```

### 3. Request Arrives at bearerAuth Middleware

**File:** `packages/soar_score_api_handlers/lib/auth/bearer_auth.dart`

- Lines 31-81: Main middleware flow
- Lines 45-56: Extracts bearer token from `Authorization` header
- Lines 58-67: Calls `verifier.verify(token)` → `Auth0TokenVerifier.verify()` validates JWT signature, expiry, issuer, audience
- Lines 70-71: Calls `resolver.resolve(verified, token)`
- Line 81: Sets `principalContextKey` on request context and calls inner handler

```dart
final token = _extractToken(request);
final verified = await verifier.verify(token);
final principal = await resolver.resolve(verified, token);
request = request.change(context: {...request.context, principalContextKey: principal});
```

### 4. Auth0TokenVerifier Validates Token

**File:** `apps/soar_score_server/lib/auth/auth0_token_verifier.dart`

- Line 38: `verify(String token)` validates JWT

### 5. Resolver Maps Identity to Account

**File:** `packages/soar_score_api_handlers/lib/auth/account_principal_resolver.dart`

- Lines 34-49: `resolve(VerifiedToken token, String accessToken)`
- Lines 35-38: Looks up identity by issuer/subject → reads `account_identities` table
- Line 39: If no identity exists, `_register(token, accessToken)` fetches the profile from `profiles.fetch(accessToken)` (Auth0 `/userinfo`) and writes the new account and identity
- Lines 41-47: Loads the account → reads `accounts` table; throws `account_not_active` when the account is missing or cannot sign in
- Line 48: Returns `Principal(accountId: account.id)`

```dart
var identity = await identities.findBySubject(
  issuer: token.issuer,
  subject: token.subject,
);
identity ??= await _register(token, accessToken);

final account = await accounts.findById(identity.accountId);
if (account == null || !account.canSignIn) {
  throw ForbiddenError('account_not_active', 'This account cannot sign in.');
}
return Principal(accountId: account.id);
```

`_register` (lines 51-98) builds the `Account` and `AccountIdentity` from the fetched profile — blanking an email another account already uses — and writes them with `accounts.save(account)` (line 85) and `identities.save(identity)` (line 86); if two first sign-ins race, the loser re-reads by subject.

### 6. Handlers Read the Principal

**File:** `packages/soar_score_api_handlers/lib/auth/principal.dart`

- Lines 64-66: `requirePrincipal(request)` reads `request.context['soar_score.principal']`

```dart
Principal requirePrincipal(Request request) {
  return request.context['soar_score.principal'];
}
```

## Key Types and Interfaces

### UserProfileSource

**File:** `packages/soar_score_api_handlers/lib/auth/user_profile.dart`, line 36

```dart
abstract interface class UserProfileSource {
  Future<UserProfile> fetch(String accessToken);
}
```

### Production Implementation: Auth0UserProfileSource

**File:** `apps/soar_score_server/lib/auth/auth0_user_profile_source.dart`, line 10

Fetches profile from Auth0's `/userinfo` endpoint using the access token.

### VerifiedToken

**File:** `packages/soar_score_api_handlers/lib/auth/token_verifier.dart`, line 5

```dart
class VerifiedToken {
  final String issuer;
  final String subject;
  // ...
}
```

### Principal

**File:** `packages/soar_score_api_handlers/lib/auth/principal.dart`, line 15

```dart
class Principal extends Equatable {
  final Id accountId;
  final Authority authority;
  final Set<Id> alsoVisibleOwners;
  // ...
}
```

## Account Data Access

### Where Account Rows Are Read

- `identities.findBySubject(issuer, subject)` — reads the `account_identities` table to find the account linked to an OAuth identity (`account_principal_resolver.dart:35-38`)
- `accounts.findById(accountId)` — reads the `accounts` table to load the account record (`account_principal_resolver.dart:41`)
- `accounts.findByEmail(email)` — during registration, checks whether the email already belongs to another account (`account_principal_resolver.dart:62`)

### Where Account Rows Are Written

- On first sign-in (a new identity), `_register` writes the new account with `accounts.save(account)` and the identity link with `identities.save(identity)` (`account_principal_resolver.dart:85-86`).

## Schema Definitions

### Schema Version

**File:** `packages/soar_score_data/lib/database.dart`, line 167

```dart
static const int currentSchemaVersion = 2;
```

### Migration Strategy

**File:** `packages/soar_score_data/lib/database.dart`, lines 173-215

Handles both fresh install (`onCreate`) and v1→v2 upgrade (`onUpgrade`). The v1→v2 migration (`_upgradeFromVersion1`) adds:

- `pilot_import_links` table
- `score_placeholders.current_attempt_id` column
- `score_placeholders.review_closed_score_revision` column
- `official_scores.selection_origin` column
- `mutation_records.aggregate_id` column
- `installation_activations.upload_open` column
- `request_throttles` table (service-only)

### Schema Version 2 Snapshot Files

- **SQLite:** `packages/soar_score_data/schema_snapshots/v2_sqlite.sql` (54 tables, 79 lines)
- **PostgreSQL:** `packages/soar_score_data/schema_snapshots/v2_postgres.sql` (54 tables, 79 lines)

### Key Account-Related Tables (v2)

- `accounts` (line 21 in both schemas): id, first_name, last_name, email, email_verified, kind (registered/guest/local/deleted), status (active/archived), is_system_admin, etc.
- `account_identities` (line 23): id, account_id, issuer, subject, created_at — the link between OAuth identity and account
- `account_aliases` (line 22)
- `account_public_profiles` (line 24)
- `participant_account_links` (line 25)

### Table Definitions

Drift table classes live under `packages/soar_score_data/lib/schema/tables/`:

- `accounts_table.dart`
- `account_identities_table.dart`
- etc.

### Migration Test

**File:** `packages/soar_score_data/test/schema/schema_v2_migration_test.dart`

## Existing Fake Authentication Patterns in Tests

### Test Files Using Fake Auth

1. `packages/soar_score_api_handlers/test/auth/account_principal_resolver_test.dart`
2. `packages/soar_score_api_handlers/test/auth/bearer_auth_test.dart`
3. `apps/soar_score_server/test/auth/auth0_user_profile_source_test.dart`

### Fake/Mock Support Files

- `packages/soar_score_api_handlers/test/auth/fake_account_repositories.dart` — in-memory `FakeAccountRepository` and `FakeAccountIdentityRepository`

### Example Fake Profile Source (Copy Pattern)

From `packages/soar_score_api_handlers/test/auth/bearer_auth_test.dart` lines 9-28:

```dart
class _Verifier implements TokenVerifier {
  String? lastToken;

  @override
  Future<VerifiedToken> verify(String token) async {
    lastToken = token;
    if (token != 'good') throw const TokenRejectedException('bad signature');
    return const VerifiedToken(issuer: 'https://t/', subject: 'sub-1');
  }
}

class _Profiles implements UserProfileSource {
  bool down = false;

  @override
  Future<UserProfile> fetch(String accessToken) async {
    if (down) throw const UserProfileUnavailableException('down');
    return const UserProfile(givenName: 'Ada', familyName: 'Lovelace');
  }
}
```

### Wiring Example

From `packages/soar_score_api_handlers/test/auth/bearer_auth_test.dart` lines 42-53:

```dart
final auth = bearerAuth(
  verifier: verifier,
  resolver: AccountPrincipalResolver(
    accounts: accounts,
    identities: FakeAccountIdentityRepository(),
    profiles: profiles,
  ),
);
handler = auth((request) {
  seen = principalOf(request);
  return Response.ok('ok');
});
```

### Alternative: fixedPrincipal for Simple Tests

Used throughout slice tests in `apps/soar_score_server/test/`:

```dart
import 'package:soar_score_api_handlers/auth/principal.dart';

// In test setup:
authMiddleware: fixedPrincipal(Principal(accountId: someAccountId)),
```

This bypasses token verification entirely and injects a fixed principal — suitable for testing route handlers and business logic without auth concerns.
