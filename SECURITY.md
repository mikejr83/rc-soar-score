# Security Policy

Thank you for helping keep RC Soar Score and the people who use it safe.

## Supported versions

RC Soar Score has not had a stable release yet. Until the first release, only the latest commit on `master` is supported. After release, this section will list the versions that receive security fixes.

## Reporting a vulnerability

**Please do not open a public issue, pull request or discussion for a security problem.**

Report it privately through GitHub:

1. Go to the [Security tab](https://github.com/mikejr83/rc-soar-score/security) of this repository.
2. Choose **Report a vulnerability**.
3. Describe the problem and how to reproduce it.

Useful details:

- The affected app or package (contest app, public site, self-scoring app, server, or a shared package) and the commit or version.
- Steps to reproduce, or a proof of concept.
- What an attacker could do, and what they would need first (for example, a signed-in account).

Please do not include real contest data, personal information about participants, or credentials in your report.

## What to expect

This is a small project maintained by one person, so these are goals, not guarantees:

- An acknowledgement within 7 days.
- An assessment and a plan within 14 days of acknowledging.
- A fix released as soon as is practical, with credit to you in the release notes if you want it.

Please give us a reasonable time to fix the problem before you disclose it publicly. We will keep you informed and agree a disclosure date with you.

## Scope

In scope:

- The API server, including authentication and authorization (Auth0 token checks) and access to contest data.
- The contest administration, public site and self-scoring apps.
- Score, result and publication integrity: anything that lets someone change or hide results they should not be able to.
- The sync protocol between the native app and the server.

Out of scope:

- Findings that need physical access to a device or an already-compromised account.
- Denial-of-service through sheer volume of traffic.
- Social engineering, and problems in third-party services we depend on (report those to the service). Auth0 tenant settings are managed by the maintainer and are not part of this repository.
- The development defaults in the repository (for example the local-only database password in `docker-compose.yml`) and the public Auth0 identifiers in the docs and code. These are not secrets.

## Secrets in this repository

No production secrets belong in this repository. If you find what looks like a real credential in the code or history, report it privately as described above.
