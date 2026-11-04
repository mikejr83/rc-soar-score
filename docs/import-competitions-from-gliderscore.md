# Import competitions from GliderScore

The Windows contest app can turn competitions in a GliderScore database into
contests. It reads the file on your computer; nothing is sent anywhere. The
file is not changed, and GliderScore does not need to be running.

Each competition you choose becomes a contest with its settings and its
participants. The draw, rounds, flights and scores are **not** imported.

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

- The draw, rounds, flights, scores and results. Scores come in a later phase.
- Retirements. A retirement belongs to a round, and there is no draw yet, so
  retired pilots stay active. The list of competitions says which ones.
- Publication settings, audio profiles, score locks, and a preliminary
  competition linked to another one.
- Street, post code, phone numbers, usual class and usual model of a pilot.
- GliderScore's own test pilots (last name starting with `ZZ`).
- The number of lanes. Soar Score has no lane count setting; the number is kept
  with the import for the draw phase to check.

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
