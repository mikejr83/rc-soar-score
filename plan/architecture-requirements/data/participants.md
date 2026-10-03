# Participants and Participation

## Participant profile

A participant profile stores reusable identity and contact data. It is always owned by one contest director, lives in that director's data, and is never shared with another director. Many participants never have an account and exist only as a profile. Email is always private.

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

A separate link relates a director's participant profile back to the account of the person it describes. It is many-to-many capable so changed emails or replacement accounts do not require rewriting contest history. A link may start as a candidate from a verified email match and becomes confirmed when the participant confirms it. Linking never shares the profile and never merges or rewrites any contest participation.

## Participant directory

A participant with an account may offer their basic details to directors, kept on their account and separate from authentication and from their public profile. Directors can search the listed entries by name, FAI number, national organization ID, or email, and copy an entry into a profile of their own. The copy is independent. The participant chooses whether to be listed and whether directors can see their email; the email is never published.

## Privacy

Director-owned participant data remains private to that director and authorized contest administration, and is never visible to another director. Published results show a participant through their public profile when a confirmed link exists, so the participant controls the name displayed, and otherwise through the profile's name and country. Public projections never include email or invitation credentials.
