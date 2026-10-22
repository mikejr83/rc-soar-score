# RC Soar Score User Interface - Participant Editor

The participant editor manages a director-owned reusable participant record. It is used from the system participant manager and from the new-contest wizard.

## Fields

Required fields are first name, last name, and email. Optional fields are club, FAI number, national organization ID, city, state/province, and country. Email is always marked private and is used for matching only; it is never included in a public contest projection.

When editing a participant profile owned by a participant account, fields controlled by that participant are read-only. Contest-specific class, role, team, number, and model values are edited on the contest participant row, not on the reusable profile.

## Behavior

The editor has `Save` and `Cancel`. Validation is inline and preserves entered values after a failed save. A duplicate or possible match by email is shown before creating a new record; the director must choose the existing record or change the email. Two participants cannot share an email, so a separate record is not created.

When opened from the wizard, a successful save returns to the wizard and adds the participant to the selection list. When opened from system management, it returns to the participant list. Unsaved changes require confirmation before leaving.

The editor must identify local and remote data, show unavailable remote matching as a recoverable state, and avoid exposing private email data in public or participant-facing views.
