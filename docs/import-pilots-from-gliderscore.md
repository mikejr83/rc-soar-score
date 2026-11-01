# Import pilots from GliderScore

The Windows contest app can add the pilots in a GliderScore database to your
participants list. It reads the file on your computer; nothing is sent
anywhere. Only pilots are imported: not contests, draws or scores.

## How to use it

1. Open **Participants** and choose **Import pilots from GliderScore…**.
2. Choose the GliderScore database (`.mdb`). GliderScore does not need to be
   running, and the file is not changed.
3. Review what was found, then choose **Import**.

The review has three groups:

- **New**: not in your list. They are added unless you untick them.
- **Already in your list**: the pilot has the same email, FAI number or
  national ID as a participant you have. The participant is updated with any
  details the file adds (see below). Untick a pilot to leave them alone.
- **Maybe the same person**: only the name matches, or the file's details
  point at more than one participant, or the pilot appears twice in the
  file. Nothing happens to these until you choose: skip (the default), add as
  new, or update one of the participants named.

The review also tells you how many GliderScore test pilots were left out and
which details were not imported.

## What is imported

| GliderScore       | Participant                                                    |
| ----------------- | -------------------------------------------------------------- |
| First, last name  | First, last name                                               |
| Email             | Email                                                          |
| FAINumber         | FAI number (`FAI_ID` is used if FAINumber is empty)            |
| OtherRegistration | National ID                                                    |
| Club, Town, State | Club, City, State                                              |
| Country           | Country, as the English name (GliderScore's code is converted) |

Not imported, because participants have no place for them: street, post code,
phone numbers, usual class and usual model. Pilots whose last name starts with
`ZZ` are GliderScore's own test data and are left out. A GliderScore number of
`0` means "none" and is ignored.

## Updating a participant you already have

- A value in the file replaces the participant's value. A blank in the file
  never clears anything.
- Names are never changed, and neither is the detail the pilot was matched on.
- Importing the same file again changes nothing and adds nobody twice.
- If you edit a participant while the review is open, nothing is saved and you
  are asked to review again, so an import never overwrites a newer edit.

## If something goes wrong

- _Importing from GliderScore is not available on this computer_: the reader
  that ships with the app could not be started. Reinstall the alpha zip and try
  again.
- _The import did not work_: the message says why (for example the file is not
  a GliderScore database or is damaged). Send the file and the message so it
  can be looked at, after checking it holds nothing you cannot share.
