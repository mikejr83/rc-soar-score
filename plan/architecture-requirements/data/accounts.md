# Accounts and Ownership

An account represents an authenticated person who can own contests, manage director-owned participant and system data, synchronize authorized contests, and claim eligible anonymous publications. The account stores a stable `accountId`, first and last name, email address, and identity-provider subject. Identity-provider identifiers are authentication keys, not contest ownership references exposed to clients.

An account may be linked to one or more participant profiles through an explicit participant-account link. Creating an account must not merge or rewrite historical contest participation automatically; any match by email is a candidate link subject to ownership and privacy rules.

Contest ownership, participant profile ownership, installation authority, and participant scoring access are separate relationships. A local operator on an administration installation acts under the contest director's authority and is not a separate offline official account.
