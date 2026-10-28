# RC Soar Score User Interface - Participant Editor

The participant editor manages a director-owned reusable participant record. It is used from the system participant manager and from the new-contest wizard.

## Fields

Required fields are first name, last name, and email. Optional fields are club, FAI number, national organization ID, city, state/province, and country. Email is always marked private and is used for matching only; it is never included in a public contest projection.

A participant profile is always the director's own editable copy. A pilot's account never changes it, so no field is read-only because of an account. Contest-specific class, role, team and number are edited on the contest participant row, not on the reusable profile. A profile also lists the person's models, which can be added or edited from the profile or from a contest participant row; the models a pilot enters in a contest are snapshotted on the row.

## Behavior

The editor has `Save` and `Cancel`. Validation is inline and preserves entered values after a failed save. A duplicate or possible match by email is shown before creating a new record; the director must choose the existing record or change the email. Two participants cannot share an email, so a separate record is not created.

When opened from the wizard, a successful save returns to the wizard and adds the participant to the selection list. When opened from system management, it returns to the participant list. Unsaved changes require confirmation before leaving.

The editor must identify local and remote data, show unavailable remote matching as a recoverable state, and avoid exposing private email data in public or participant-facing views.

## Directory updates

When a director adds a participant, and later whenever the app is online, it checks the participant directory by exact normalized email, FAI number and national organization ID. If it finds a listed entry or newer details, it shows a notice with one tap to use the pilot's details. `Refresh` is the same action. Nothing is overwritten without that tap. Offline, the checks are skipped quietly and run when the app is connected. The director never learns that an unlisted account exists.

## Unlinking

A pilot can end a confirmed link to a director's profile from their account. Unlinking never changes anything already published. It only affects later publications, which use the name the director typed, and the pilot's own contest list. The unlink screen says this in plain words.
