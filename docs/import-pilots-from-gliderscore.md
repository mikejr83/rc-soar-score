# Import pilots from GliderScore

The Windows contest app can add the pilots in a GliderScore database to your
participants list. It reads the file on your computer. Your participants and
remembered links sync with your account. Only pilots are imported: not contests, draws or scores. To import
competitions as contests, see
[import competitions](import-competitions-from-gliderscore.md).

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

Once you confirm a pilot, the app remembers the link for both pilot and competition imports. A remembered pilot shows “Linked to” the participant. If GliderScore details change later, select the pilot to approve importing the changes. Deleting a participant removes its remembered links.

Links identify the director's GliderScore 6 database and pilot number; saving the database or adding competitions does not break them. Distinguishing an independent GliderScore database on a different computer from a transferred database is not yet supported. Earlier imports establish links when next confirmed.

One computer manages the remembered links for your account: the first one that confirms a pilot. Other computers can still import GliderScore pilots and competitions, but they show a notice and offer **Import without remembered links**. You confirm each match yourself for that import, and the saved links stay as they are. The account refuses link changes from a computer that does not manage them, even ones made offline and sent later. Moving the links to a replacement computer is not supported yet.

If a link was already confirmed differently on two computers, importing that pilot is held back (the other pilots in the file import normally) until you decide in **Account sync** (the sync status at the bottom of the window opens it). You can keep the saved link, use the other one, or choose a different participant; if that participant was deleted in the meantime you are asked to pick another. If the link changes while you are reviewing, the comparison is refreshed and you decide again. Deleting a participant removes its link, and the pilot is linked again the next time you import it.

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
