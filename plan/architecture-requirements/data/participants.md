# Participants and Participation

## Participant profile

A participant profile stores reusable identity and contact data. It may be director-owned, local-only, or shared by a participant account that has opted into sharing. Email is always private and must have an explicit visibility policy.

Required: first name, last name. Optional: club, FAI number, national organization ID, city, state/province, country, and email.

A profile is not itself a contest entry and has no class, role, team, start number, or score.

## Contest participation link

A participation link joins one participant profile to one contest. It is the authoritative contest snapshot and contains:

- contest-specific class;
- role reference and role type (`Pilot` or `NonFlier`);
- contest start/participant number, if enabled;
- team reference, if teams are enabled;
- scoring UUID used as a contest-scoped public identifier;
- for a pilot, the round from which they retired, if they have.

The link is the parent of the participant's assignments, score placeholders, invitations, and contest model links. Scores must reference the link, not only the reusable profile.

Participant numbers come from one running sequence per contest that is shared by all role types. They are allocated at the first applicable draw and are not renumbered. A participant added later receives the next available number.

The link does not copy the profile's identity details. They are read from the profile, and a publication takes its own copy of the details it shows.

## Participant-account link

A separate link may associate a participant profile with a user account. It is many-to-many capable so changed emails or replacement accounts do not require rewriting contest history. Account ownership and participant data-sharing consent are recorded separately.

## Privacy

Director-owned participant data remains private to that director and authorized contest administration. A shared profile may become read-only to directors according to participant consent. Public projections expose only the allowed display fields, at minimum name and country when configured; never email or invitation credentials.
