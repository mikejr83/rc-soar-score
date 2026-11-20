# Architecture decision records

An architecture decision record (ADR) captures one significant technical decision: the situation, what was decided, and what follows from it. ADRs are kept in the repository so the reasons survive after the discussion in the issue is closed. The decision issue, where there is one, is linked in each record's header. Part of the [documentation](../README.md), licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

## Index

| ADR                                            | Title                                                    | Status                                 | Date       |
| ---------------------------------------------- | -------------------------------------------------------- | -------------------------------------- | ---------- |
| [0001](0001-identity-provider-auth0.md)        | Use Auth0 as the identity provider                       | accepted                               | 2026-10-05 |
| [0002](0002-score-entry-layout.md)             | Score entry layout for the contest administration app    | accepted                               | 2026-10-05 |
| [0003](0003-hosting-platform.md)               | Managed hosting for release 1                            | accepted                               | 2026-10-06 |
| [0004](0004-localization-approach.md)          | Localization approach for the contest administration app | accepted                               | 2026-10-19 |
| [0005](0005-public-site-nextjs.md)             | The public site is a Next.js app                         | accepted                               | 2026-10-23 |
| [0006](0006-gliderscore-import-persistence.md) | Persistence of imported GliderScore contests             | proposed (amended)                     | 2026-11-03 |
| [0007](0007-transactional-email.md)            | Transactional email delivery                             | accepted for provider and environments | 2026-11-19 |

## Adding an ADR

1. Take the next number, zero-padded to four digits, and name the file `NNNN-short-kebab-title.md` in this folder.
2. Start from the header and sections the existing records use:

   ```markdown
   # ADR NNNN: Title

   - Status: proposed
   - Date: YYYY-MM-DD
   - Decision issue: #123

   ## Context

   What forces the decision: the situation, constraints and what was open.

   ## Decision

   What was decided, as specific and checkable statements.

   ## Consequences

   What follows: costs, follow-up work and what becomes easier or harder.
   ```

   Records add sections when they help, such as "Rejected options" (0004, 0006) or "Implementation" (0006).

3. Set the status to `proposed` until the decision is made, then `accepted`. Link the decision issue in the header (the header may say `none` when there is no issue, as in 0005).
4. Add the record to the index table above.
5. Link to it from the docs or code it affects, as the deploy pages do with ADR 0003.

## Changing a decision

Do not rewrite an accepted record to change history. Record a later change as a dated amendment section in the same file, saying which earlier text it replaces (ADR 0006 does this), or write a new ADR that says which one it supersedes and note that in the old record's status. Small corrections that keep the original meaning, such as a fixed link or a changed host name, can be edited in place.
