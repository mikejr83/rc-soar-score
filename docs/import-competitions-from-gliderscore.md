# Import competitions from GliderScore

The Windows contest app can turn competitions in a GliderScore database into
contests. It reads the file on your computer; nothing is sent anywhere. The
file is not changed, and GliderScore does not need to be running.

Each competition you choose becomes a contest with its settings and its
participants. You can add the draw in a second run. Scores, penalties and
re-flights are **not** imported.

## How to use it

1. On the **Contests** page, choose **Import from GliderScore…**.
2. Choose the GliderScore database (`.mdb`).
3. Tick the competitions to import. None are ticked to begin with. A competition
   that cannot be imported has no checkbox and says why.
4. Review the pilots of the competitions you chose. This is the same review as
   [importing pilots](import-pilots-from-gliderscore.md): new pilots are added,
   pilots you already have are updated, and a pilot who might be someone you
   already have waits for your choice.
5. Check the summary and choose **Import**.
6. The last step shows what happened to each competition. **Open** goes
   straight to the new contest.

## What is imported

- The name, the venue and the date. GliderScore stores no time zone, so the
  contest uses the time zone of this computer; the end date is the start date.
- The scoring settings that Soar Score has a place for, such as the target
  time, drops and team scoring. A setting that is out of range is replaced by a
  safe value, and the list of competitions says so.
- Every participant, with their role (pilot, helper, team manager or
  competition director), start number and team. GliderScore has no team
  names, so teams are named Team 1, Team 2 and so on. Rename them afterwards.
- The pilots themselves, as participants in your list.

The new contest is in **Configuring** with scoring closed. You finish it as
any contest: check the settings, then build the draw.

## What is not imported

- Scores, penalties, re-flights and results. Every flight waits for a score,
  and a later import phase will bring them.
- Retirements. They are not imported, so retired pilots stay active. The list
  of competitions says which ones.
- Publication settings, audio profiles, score locks, and a preliminary
  competition linked to another one.
- Street, post code, phone numbers, usual class and usual model of a pilot.
- GliderScore's own test pilots (last name starting with `ZZ`).
- The lane count setting. Soar Score has none; the draw uses it once (see
  below) and the number stays with the import.

## Adding the draw

A competition you imported before offers its draw the next time you choose
**Import from GliderScore…** with the same file. The row says how many rounds,
groups per round and pilots the draw has. Tick it and choose **Import**; adding
a draw needs no pilot review.

- The contest gets the rounds, groups and every pilot's place as GliderScore
  drew them, and becomes **Ready**. It is a copy of the draw at that moment.
  It cannot be reproduced from a seed; rounds without scores can be redrawn like
  any other.
- If the competition has lanes, each pilot's lane follows their place in the
  group. A place beyond the lane count gets the next lane, and the row warns
  about it. If the competition has no lanes, none are set and the order in each
  group is kept with the import.
- The draw is offered only while the contest has no draw and no scores. The
  row says why when it is refused, for example because the contest already has
  a draw or the file changed since the contest was imported.
- A flight that was moved to another round in GliderScore cannot be imported.
- The row warns when the last rounds have no scores in GliderScore, because they
  may not have been flown.
- A draw added by mistake cannot yet be replaced by importing again. Delete the
  contest and import it again.

The contest workspace shows a note, from the date of the import, saying what
the import left out. It disappears with the contest.

## Which competitions can be imported

- **F5J** competitions can be imported.
- **F3J**, **DurGeneral** and **DurALES** are planned but not imported yet.
- **F3B**, **F3K**, **F3L**, **F5B**, **F5L**, speed and electric classes are
  not supported by Soar Score.
- A competition is also blocked when its settings or date are missing from the
  file, its settings are not valid, or nobody in it can be imported.

The mapping was checked against GliderScore database version **6.78**. A file of
another version still imports, but the list warns that it was not tested.

## Importing the same file again

A competition that was imported from the same file before is not imported
again: the last step says "already imported" with the date, and changes
nothing. Delete the contest first if you want to import it again. A changed
file counts as a different file; reconciling a changed file with a contest you
already edited is not supported yet.

If one competition fails, the others are still imported, and the failed one
leaves nothing behind. Pilots saved in step 4 stay in your participants list.

## If something goes wrong

- _Importing from GliderScore is not available on this computer_: the reader
  that ships with the app could not be started. Reinstall the alpha zip and try
  again.
- _The import failed_ or a competition says why it was not imported: send the
  file and the message so it can be looked at, after checking the file holds
  nothing you cannot share. Mention the GliderScore version.
- _A participant you chose is no longer in your list_: you changed your list
  while the import ran. Import again.
