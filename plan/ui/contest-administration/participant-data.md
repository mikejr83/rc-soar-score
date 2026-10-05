# RC Soar Score User Interface - Participant Editor

The participant editor manages a director-owned reusable participant record. It is used from the system participant manager and from the new-contest wizard. A participant record always belongs to one director and is never shared with another director.

## Fields

Required fields are first name and last name. Optional fields are email, club, FAI number, national organization ID, city, state/province, and country. Email is always marked private. It is used for matching together with FAI number and national organization ID, never name, and it is never included in a public contest projection.

Contest-specific class, role, team, number, and model values are edited on the contest participant row, not on the reusable record.

## Participant directory

A participant with an account may offer their details in the participant directory. The editor can search the directory by name, FAI number, national organization ID, or email, and copy an entry into the director's own record, either when creating a record or into an existing one. The copy is independent: later changes the participant makes to their directory entry do not change the director's record until the director refreshes it from the directory. Refreshing shows the values that would change before applying them.

When the participant has chosen to hide their email from directors, the copied record shows the email as "available to the system" instead of the address. It can still be used for matching.

## Behavior

The editor has `Save` and `Cancel`. Validation is inline and preserves entered values after a failed save. A duplicate or possible match by email, FAI number, or national organization ID is shown before creating a new record; the director must choose the existing record or explicitly create a separate local record where permitted.

When opened from the wizard, a successful save returns to the wizard and adds the participant to the selection list. When opened from system management, it returns to the participant list. Unsaved changes require confirmation before leaving.

The editor must identify local and remote data, show unavailable remote matching or directory search as a recoverable state, and avoid exposing private email data in public or participant-facing views.
