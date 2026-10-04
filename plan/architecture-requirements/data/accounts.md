# Accounts and Ownership

An account represents a person within the backend. It can own contests, manage director-owned participant and system data, synchronize authorized contests, and claim eligible anonymous publications. The account stores a stable `accountId`, first and last name, an optional email address stored in lowercase, and whether the identity provider has verified that email. Identity-provider identifiers (the issuer and subject) are authentication keys. They are held separately from the account, so one account can have more than one login and the provider can change, and they are never exposed to clients or used as contest ownership references.

## Account kinds

An account is one of four kinds:

- **Registered:** a person who signs in through an identity provider. Only registered accounts can sign in. Email is unique among registered accounts that have one.
- **Guest:** created when someone redeems an invitation without having an account, so that their submissions have an actor. A guest cannot sign in and its email is never treated as verified.
- **Local:** the account that owns data created offline on an installation. It is claimed into a registered account when the user registers or signs in.
- **Deleted:** a single shared account, created by the system, that references point at after the person they belonged to has been erased.

A registered account is `active` or `archived`. An archived account cannot sign in, and all its data is retained.

## Claiming

A guest or local account is claimed into a registered account by re-pointing every reference to it (ownership, actors, invitations, participant links) to the registered account. Claiming is one-directional and happens once per account. A registered account is never merged into another account. A guest account is claimed only by someone who redeems the invitation or claim link.

## Participants, the directory, and the public profile

An account may be linked to one or more participant profiles through an explicit participant-account link. Creating an account must not merge or rewrite historical contest participation automatically. A match by verified email is only a candidate link, which the participant must confirm. Linking never copies account data into a director's profile.

A participant with an account may offer basic details in a participant directory, kept on the account and separate from authentication. A contest director can find a listed entry and copy it into their own participant profile. The participant chooses whether to be listed and whether directors can see their email.

Publications never reference an account. They reference the account's public profile, which holds only the information the person chose to make public, such as the name shown in results. Unlinking the public profile from an account detaches the person from published data without changing published results.

## Anonymous publishers

A contest director who publishes without an account has no account at all. The publication is identified by a verified private email address and has no owner until a registered account with that verified email claims it.

## Deleting an account

A deletion request removes data in the backend only. Data entered by a contest director belongs to that director and is never removed at another person's request. The person chooses what to remove:

1. Close the account only. The account is archived and all data is retained.
2. Remove their contest data. The working data of every contest the account owns is deleted. Published results remain, with their link to the contest cleared, and a delist request is raised for each publication for a system administrator to review.
3. Remove their participation records. Their details in published results are redacted automatically and the public profile is unlinked.

When the account is erased, its identities, participant links, and directory entry are deleted, the director's participant profiles and participations stay, references to it from other directors' contests are re-pointed to the deleted-user account, and the account row is removed.

Published results are public record that other people rely on. A publication cannot be removed by its owner directly: removing one is a request that a system administrator decides.

## System administrator

A system administrator is an account flagged by the backend itself. The flag is never settable through a client request. An administrator decides delist requests and can redact a participant's details in published results when that participant has no account.

## Scope

Contest ownership, participant profile ownership, installation authority, and participant scoring access are separate relationships. In the first release a contest has a single owner, officials act on the owner's behalf, and a self-scorer acts through an invitation. A local operator on an administration installation acts under the contest director's authority and is not a separate offline official account.

Accounts are a backend concern and are not synchronized to installations. An installation holds only its own local account. Records inside contests carry account identifiers as opaque actor references, and installations do not enforce foreign keys on them.
