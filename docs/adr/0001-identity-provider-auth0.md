# ADR 0001: Use Auth0 as the identity provider

- Status: accepted
- Date: 2026-10-05
- Decision issue: #75

## Context

The plan uses OIDC Authorization Code with PKCE in the apps and JWT validation on the server. Cost matters, so the account is not created until real accounts are needed.

## Decision

Use the Auth0 free plan as the identity provider.

- The server depends only on OIDC and JWT validation. Switching providers later changes the issuer URL, audience and client SDK only.
- Milestone M1 runs on the development-only token verifier (#112), which refuses to start when `ENV=production`.
- The Auth0 tenant is created when real sign-in work (#148) starts in milestone M2. A separate production tenant is created before release.
- No client secret is ever needed: the server validates tokens against Auth0's public keys.

## Consequences

- Free plan limits come from third-party summaries and must be confirmed on Auth0's pricing page when the account is created: 25,000 monthly active users, one custom domain (needs a card on file), no multi-factor authentication.
- If the free plan stops fitting, Supabase Auth or Firebase Auth are the fallbacks, with the same code-level impact.
